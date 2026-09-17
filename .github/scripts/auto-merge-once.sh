#!/usr/bin/env bash
# Extracted from auto-merge-trigger.yml so both the main pull_request_target job and the
# Dependabot-classification retrigger job (workflow_run-triggered, no PR-event context of its
# own) can share one admission-attempt implementation instead of drifting apart.
#
# Required env: REPO, PR, PR_URL, GH_TOKEN (CODEX_REVIEW_PAT). PR_AUTHOR and PR_HEAD_SHA are
# additionally required for the default (full admission-attempt) mode -- not needed when
# called with `disarm-and-verify` as $1 (see below). EVENT_ACTION/EVENT_LABEL are optional
# (unset when called from the workflow_run-triggered retrigger job, which has no PR-event
# action at all) -- referenced with `${VAR:-}` wherever read, never required.
set -euo pipefail

# Fails CLOSED: echoes "unknown" (not "absent") when the labels API call itself fails, so a
# transient failure can't be silently read as "the label isn't there." A bare `grep` against
# a command substitution that failed and produced empty output is indistinguishable from a
# confirmed-empty label list -- every call site below must treat "unknown" the same as (or
# more conservatively than) "present," never the same as "absent."
label_state() {
  local label="$1" labels
  if ! labels=$(gh api --paginate "repos/${REPO}/issues/${PR}/labels" --jq '.[].name' 2>/dev/null); then
    echo "unknown"
    return
  fi
  if grep -qxF "$label" <<< "$labels"; then
    echo "present"
  else
    echo "absent"
  fi
}

dequeue_and_disarm() {
  gh pr merge "$PR_URL" --disable-auto >/dev/null 2>&1 || true
  OWNER_PART="${REPO%%/*}"; NAME_PART="${REPO##*/}"
  queue_state=$(gh api graphql -f query='
    query($owner: String!, $name: String!, $pr: Int!) {
      repository(owner: $owner, name: $name) {
        pullRequest(number: $pr) { id isInMergeQueue }
      }
    }' -f owner="$OWNER_PART" -f name="$NAME_PART" -F pr="$PR" 2>/dev/null)
  pr_node_id=$(printf '%s' "$queue_state" | jq -r '.data.repository.pullRequest.id')
  in_queue=$(printf '%s' "$queue_state" | jq -r '.data.repository.pullRequest.isInMergeQueue')
  if [ "$in_queue" = "true" ] && [ -n "$pr_node_id" ] && [ "$pr_node_id" != "null" ]; then
    echo "::notice::PR #$PR is in the native merge queue (autoMergeRequest alone wouldn't have caught this) -- dequeuing."
    gh api graphql -f query='mutation($id: ID!) { dequeuePullRequest(input: {id: $id}) { clientMutationId } }' -f id="$pr_node_id" >/dev/null 2>&1 || true
  fi
}

# Fail CLOSED (report "still armed/queued", i.e. unsafe) when the verification query itself
# can't be trusted.
still_armed_or_queued() {
  local state armed queued
  OWNER_PART="${REPO%%/*}"; NAME_PART="${REPO##*/}"
  if ! state=$(gh api graphql -f query='
    query($owner: String!, $name: String!, $pr: Int!) {
      repository(owner: $owner, name: $name) {
        pullRequest(number: $pr) { autoMergeRequest { enabledAt } isInMergeQueue }
      }
    }' -f owner="$OWNER_PART" -f name="$NAME_PART" -F pr="$PR" 2>/dev/null); then
    echo "::error::Could not fetch PR #$PR's live armed/queued state to verify disarm -- treating as unsafe (fail closed)." >&2
    return 0
  fi
  armed=$(printf '%s' "$state" | jq -r '.data.repository.pullRequest.autoMergeRequest != null' 2>/dev/null)
  queued=$(printf '%s' "$state" | jq -r '.data.repository.pullRequest.isInMergeQueue' 2>/dev/null)
  if { [ "$armed" != "true" ] && [ "$armed" != "false" ]; } || { [ "$queued" != "true" ] && [ "$queued" != "false" ]; }; then
    echo "::error::Could not parse PR #$PR's live armed/queued state to verify disarm -- treating as unsafe (fail closed)." >&2
    return 0
  fi
  [ "$armed" = "true" ] || [ "$queued" = "true" ]
}

# Provenance is checked against the label's own most recent application (via the PR's
# timeline `labeled` event), not just marker content -- only a marker posted AT OR AFTER that
# event can be trusted to describe THIS application. Fail closed whenever provenance can't be
# confirmed: no labeled event, no marker, or a marker older than the most recent labeling.
needs_review_is_stale() {
  local current_head_sha12="$1"
  local last_labeled_at marker_info marker_created_at recorded_sha12
  local raw
  if raw=$(gh api --paginate --slurp "repos/${REPO}/issues/${PR}/timeline" 2>/dev/null); then
    last_labeled_at=$(printf '%s' "$raw" | jq -r '(add // []) | [.[] | select(.event == "labeled" and .label.name == "needs-review")] | if length > 0 then (last | .created_at) else "" end' 2>/dev/null)
  else
    last_labeled_at=""
  fi
  [ -z "$last_labeled_at" ] && return 1
  if raw=$(gh api --paginate --slurp "repos/${REPO}/issues/${PR}/comments" 2>/dev/null); then
    marker_info=$(printf '%s' "$raw" | jq -r '(add // []) | [.[] | select(.user.login == "github-actions[bot]") | select(.body | test("queue-retry-handler:needs-review sha=[0-9a-f]{12}")) | [.created_at, (.body | capture("queue-retry-handler:needs-review sha=(?<s>[0-9a-f]{12})").s)] | @tsv] | if length > 0 then last else "" end' 2>/dev/null)
  else
    marker_info=""
  fi
  [ -z "$marker_info" ] && return 1
  marker_created_at=$(cut -f1 <<< "$marker_info")
  recorded_sha12=$(cut -f2 <<< "$marker_info")
  [ -z "$recorded_sha12" ] && return 1
  [[ "$marker_created_at" < "$last_labeled_at" ]] && return 1
  [ "$recorded_sha12" = "$current_head_sha12" ] && return 1
  # dependabot-auto-merge.yml's own classify step co-applies major-update alongside
  # needs-review for a major bump, and never removes it on a later push -- if it's still
  # present, needs-review is (at minimum also) the classifier's own pause, not solely a
  # queue-retry-handler marker-tracked one, regardless of what the provenance check above
  # concluded. A concurrent synchronize can reclassify the SAME major bump on a new head
  # without generating a fresh `labeled` timeline event at all (attaching an
  # already-present label is a no-op event-wise), which would otherwise let this function
  # read the OLD labeled event/an unrelated marker as proof of staleness and clear a pause
  # that's still the classifier's own live decision. Fail closed on "unknown" too (the API
  # call itself failed) -- treat it the same as "present," not "absent": an unconfirmed
  # label state must not let this function conclude the pause is safe to clear.
  if [ "$(label_state major-update)" != "absent" ]; then
    return 1
  fi
  return 0
}

# The actual admission attempt -- author/classification gate, merge_queue-live gate, base
# gate, then the merge call itself, pinned to the exact head this decision was made against.
attempt_admission() {
  if [ "$PR_AUTHOR" = "dependabot[bot]" ]; then
    # NOT gated on major-update here, deliberately -- only on needs-review (via the
    # merge_queue_live/base/needs-review flow this function is reached through). This
    # matches sunto's original .mergify.yml exactly: major-update was always a purely
    # DESCRIPTIVE classification label, never an independent admission condition of its
    # own -- the documented approval path for a major bump is a maintainer reviewing it and
    # removing ONLY needs-review, leaving major-update in place as a historical marker. An
    # earlier version of this check also gated on major-update directly, which broke that
    # exact path: dependabot-auto-merge.yml never removes major-update itself, so a
    # maintainer's approval could never actually un-stick the PR. major-update is still
    # checked -- inside needs_review_is_stale() above -- to stop this function's OWN
    # staleness-clearing logic from auto-clearing a pause the classifier still actively
    # wants; that's a different, narrower concern than gating admission here a second time.
    auto_merge_conclusion=$(gh api "repos/${REPO}/commits/${PR_HEAD_SHA}/check-runs" --jq '[.check_runs[] | select(.name == "auto-merge")] | last | .conclusion // "absent"' 2>/dev/null || echo "absent")
    if [ "$auto_merge_conclusion" != "success" ]; then
      echo "::notice::PR #$PR is a Dependabot PR whose 'auto-merge' check-run is '${auto_merge_conclusion}', not success -- standing down without arming (classify workflow hasn't vetted this revision, or vetted it as needing review)."
      return 0
    fi
  elif [ "$PR_AUTHOR" != "thagale" ]; then
    # A maintainer removing needs-review from a PR they manually admitted despite its
    # author not being on this allowlist (this job's own `if:` in auto-merge-trigger.yml
    # already lets exactly that `unlabeled` event reach this script) is a trusted RESUME of
    # a prior manual decision, not a fresh admission request -- the label removal is the
    # signal to honor here, the same way auto-merge-trigger.yml's own `labeled` handling
    # already treats a matching label event as authoritative regardless of author. Without
    # this, the documented pause/resume flow for a manually-admitted outside contributor
    # would leave the PR stuck: the earlier `labeled` event already disarmed it, so removing
    # the label is the ONLY thing that could ever re-arm it, and this gate would reject that
    # unconditionally based on authorship alone. EVENT_ACTION/EVENT_LABEL are unset (not
    # just empty) when this function is reached from the workflow_run-triggered retrigger
    # job, which has no PR-event action at all -- `${VAR:-}` avoids tripping `set -u` there.
    if [ "${EVENT_ACTION:-}" = "unlabeled" ] && [ "${EVENT_LABEL:-}" = "needs-review" ]; then
      echo "::notice::PR #$PR's author ($PR_AUTHOR) is not on the trusted-author allowlist, but this is a needs-review removal (a resume of a prior manual admission) -- proceeding."
    else
      echo "::notice::PR #$PR's author ($PR_AUTHOR) is not on the trusted-author allowlist -- standing down without arming."
      return 0
    fi
  fi

  merge_queue_live=$(gh api "repos/${REPO}/rules/branches/main" --jq '[.[] | select(.type == "merge_queue")] | length > 0' 2>/dev/null || echo false)
  if [ "$merge_queue_live" != "true" ]; then
    echo "::notice::No merge_queue ruleset rule exists yet for main -- standing down without arming native auto-merge on PR #$PR. Mergify's own queue is still the sole merge authority until the ruleset write lands."
    return 0
  fi
  current_base=$(gh pr view "$PR" --repo "${REPO}" --json baseRefName --jq .baseRefName)
  if [ "$current_base" != "main" ]; then
    # Deliberately does NOT disarm/dequeue here -- see auto-merge-trigger.yml's own header
    # comment for the full reasoning (an earlier version of this file actively disarmed a
    # PR retargeted away from main; backed out after three review rounds each surfaced a
    # deeper bug in that one code path -- not worth the surface area for a gap whose
    # worst case is a stale queue entry needing a manual dequeue, not a security hole).
    echo "::notice::PR #$PR's base is '$current_base' (not main) as of this mutation attempt -- standing down without arming."
    return 0
  fi
  # Re-check needs-review immediately before mutating, not just once at the top of the
  # script: every check above this point (the Dependabot check-run lookup, merge_queue_live,
  # current_base) costs real wall-clock time, during which a concurrent event -- the
  # classifier attaching needs-review for a major update (dependabot-auto-merge.yml), or a
  # maintainer manually pausing an already-green PR -- can land needs-review after the
  # original read but before this call. `gh pr merge --help` confirms that once required
  # checks have already passed, this call adds the PR directly to the native merge queue,
  # which doesn't itself enforce needs-review at all -- so a pause applied in that window
  # would have no effect unless caught here. Deliberately only needs-review, matching
  # admission's actual rule elsewhere in this function (see the major-update comment above);
  # not re-running every check from scratch, just closing the specific window this call
  # itself is exposed to.
  if [ "$(label_state needs-review)" != "absent" ]; then
    echo "::notice::PR #$PR now has needs-review attached (applied after this attempt's original label read) -- standing down without arming."
    return 0
  fi
  # --match-head-commit: without it, a Dependabot PR pushed AFTER PR_HEAD_SHA was captured
  # (and validated above) but BEFORE this call executes could get armed against its new,
  # unclassified head instead of the one whose 'auto-merge' check-run was actually checked --
  # admitting a newly-changed major update before its classifier ever attaches needs-review.
  # `gh pr merge --help` defines this flag as requiring the PR head to match before allowing
  # the merge, so a stale PR_HEAD_SHA here makes the call fail instead of silently arming the
  # wrong revision.
  gh pr merge "$PR_URL" --auto --squash --match-head-commit "$PR_HEAD_SHA"
}

# disarm-and-verify mode ($1): used by the `labeled: needs-review` handler in
# auto-merge-trigger.yml, which only needs to disarm and confirm it -- not run the full
# admission-attempt flow (which would immediately re-check the same label that's meant to
# be blocking it). Verifying and failing loudly here (instead of the previous inline
# implementation's swallowed-failure `|| true` with no check at all) closes a real gap: a
# transient dequeue/disarm failure used to report success regardless, leaving a PR the
# label claims is paused still armed or queued, since the native queue doesn't itself
# enforce this label.
if [ "${1:-}" = "disarm-and-verify" ]; then
  dequeue_and_disarm
  if still_armed_or_queued; then
    echo "::error::Could not fully disarm PR #$PR after needs-review was attached -- refusing to report success. Disarm by hand (gh pr merge $PR --disable-auto --repo $REPO, and dequeue via the PR's own UI if still queued) and confirm." >&2
    exit 1
  fi
  exit 0
fi

current_labels=$(gh api --paginate "repos/${REPO}/issues/${PR}/labels" --jq '.[].name')
if grep -qxF "needs-review" <<< "$current_labels"; then
  current_head_sha12=$(gh pr view "$PR" --repo "${REPO}" --json headRefOid --jq '.headRefOid[0:12]')
  if needs_review_is_stale "$current_head_sha12"; then
    echo "::notice::needs-review on PR #$PR is stale (provably tied to an earlier revision's queue-retry-handler pause, not the current head $current_head_sha12) -- clearing it and proceeding to evaluate admission for the new revision."
    gh api --method DELETE "repos/${REPO}/issues/${PR}/labels/needs-review" >/dev/null 2>&1 || true
    # Verify the delete actually took before arming: a transient DELETE failure swallowed by
    # `|| true` must not let this fall through to attempt_admission, since arming here while
    # the pause is still visibly attached defeats the entire point of checking it above.
    labels_after_delete=$(gh api --paginate "repos/${REPO}/issues/${PR}/labels" --jq '.[].name')
    if grep -qxF "needs-review" <<< "$labels_after_delete"; then
      echo "::error::Could not remove the stale needs-review label from PR #$PR -- refusing to arm auto-merge while it remains attached. Remove it by hand, then rerun this job." >&2
      exit 1
    fi
    attempt_admission
  else
    echo "::notice::PR #$PR has needs-review covering its current head (or its provenance could not be confirmed) -- standing down without arming; ensuring auto-merge is not armed/queued despite the label."
    dequeue_and_disarm
    if still_armed_or_queued; then
      echo "::error::Could not fully disarm PR #$PR while needs-review is attached -- refusing to report success while it remains armed or queued. Disarm by hand and confirm." >&2
      exit 1
    fi
  fi
else
  attempt_admission
fi
