# wiki-kit — Implementation & Rollout Plan

Opus implements; this plan is ordered so every phase leaves something useful
even if the next never happens. SPEC.md is normative throughout; where the
plan and spec disagree, the spec wins.

## P0 — Kit foundation (`ricettario` repo)

Scaffold the repo (`plugin/`, `bin/wiki-lint`, `templates/`, `schema/`,
`fixtures/`). Implement `wiki-lint` per SPEC §6 with the restricted
frontmatter parser (§2.1) — write the parser against grammar test vectors
(valid + a battery of rejected full-YAML constructs) before the checks.
Build the golden fixture wiki: a mini-repo with git history engineered to
exercise WK-W11 (touched source), WK-W12 (age), WK-L10 (stale manifest),
glob sources, `url:` sources, an unresolvable `verified.commit`.

**Accept when:** lint on the fixture reproduces the expected findings exactly;
`--manifest`/`--index` output is byte-identical across two runs and across
macOS/Linux; manifest validates against `wiki-manifest.v1.schema.json`;
CI recipe (single job: `wiki-lint`) documented in README.

## P1 — Skills + pilot on two deliberately different repos

Write the five skills per SPEC §9 as a Claude Code plugin; templates for each
page kind; the CLAUDE.md stanza installer.

Pilot A — **skimmer** (greenfield, design-phase): init should distill the
existing README/ARCHITECTURE/SPEC/ROADMAP into pointer-heavy pages plus
genuine wiki content (the Watterson-dependency saga is a ready-made `gotcha`;
the V8w/fixture-freeze rule a `decision-digest`; the coppa-dsp reuse
boundary an `interface`). Good test of the routing rule on a repo where the
docs are already excellent.

Pilot B — **BeatScope** (mature, code + doc-heavy): the hard case. Init must
resist re-describing `docs/fault-detection/` and instead capture what is NOT
written down: build/run runbooks, the TS↔Python parity workflow, device
quirks, where fixtures live.

**Accept when:** both wikis lint clean in CI; a fresh Claude Code session in
each repo, given a representative task, demonstrably consults the wiki
(reads INDEX + a page) instead of re-exploring; `/wiki-update` after a real
work session produces a sensible delta with zero normative restatement (spot-
check against the drift-firewall rule); Tony has reviewed and kept ≥ 80 % of
seed pages (if he deletes more, the distillation prompts are miscalibrated —
iterate before rolling out).

## P2 — Fleet rollout

Order: **coppa, pancetta, cqdx** (the dispensa triangle — their wikis get
`interface` pages citing Q/ADR ids), then **propagation, dit, watchfinder,
health, sbn, panino, remy**, finally **dispensa itself** (a small wiki
digesting the contract landscape — who owes whom what — is legitimately
descriptive). Per repo: `/wiki-init`, review, commit, CI job.

Migration sweep, once per repo: long-lived knowledge currently squatting in
CLAUDE.md (e.g. skimmer's Watterson correction bullet) moves to a wiki page;
CLAUDE.md keeps one pointer line. Auto-memory project facts migrate to the
owning repo's wiki; the memory file shrinks to pointers. This is the durable
fix for "persist everything before the session dies."

**Accept when:** all repos lint-clean with the stanza installed; auto-memory
contains no project knowledge that isn't in a repo wiki; one full
`/wiki-verify` + `/wiki-gc` cycle run somewhere to prove the loop.

## P3 — claude.ai Projects

For each Project: GitHub-synced → confirm `wiki/` appears in project
knowledge, done. Not synced → `/wiki-export`, upload digest, note the
regeneration command in the Project instructions. Add a line to each
Project's instructions mirroring the CLAUDE.md stanza (read INDEX first).

**Accept when:** every active Project answers a repo-knowledge question from
wiki content without file exploration; digest regeneration is one command.

## P4 — Harbor federation (blocked on harbor P3: vault + indexer exist)

Harbor-side (belongs in harbor's repo, against DATA-CONTRACTS): add
`repo-wiki` source type to the vault indexer — config lists manifest
locations; ingest keyed on `(repo, id)`, re-embed on `hash` change; map
manifest `visibility` → namespace (public → shared-safe, private →
`private:argus`); honor `status` (exclude or down-rank `stale`); trust per
harbor policy (recommended: `trusted`, per the commit-gate argument in
ARCHITECTURE §4 — but this is harbor's call and its config). Write-back only
as PRs (`propose_edit` pattern).

Gardener: weekly scheduled run (harbor n8n once live; Claude Code cron
`claude -p "/wiki-verify then /wiki-gc"` per repo until then) — fits the
existing weekly-ops budget.

**Accept when:** a harbor-side query ("why does skimmer oversample the PFB?")
retrieves the right wiki chunk with correct provenance; a closed-repo (cqdx)
page is retrievable for argus and structurally absent for a bocephus
principal; editing a page and re-running the indexer re-embeds exactly one
chunk set.

## Risks & mitigations

- **Agents don't update (the #1 failure mode):** the stanza makes
  `/wiki-update` part of definition-of-done, and WK-W11/W12 make neglect
  visible in CI warnings rather than silent. If pilots show updates still
  get skipped, escalate to a Stop-hook nudge — but try discipline before
  machinery.
- **Bloat / restated-spec drift:** hard caps (WK-L3/L8), the routing rule,
  gc's "wrong > missing" deletion policy, and pilot review calibration.
- **Staleness theater** (pages perpetually `stale`, never adjudicated): the
  gardener cadence exists precisely for this; `stale` count is the one metric
  worth glancing at monthly.
- **Fork drift of lint across repos:** single source in ricettario, version
  stamp, WK-L10 keeps manifests honest even if versions skew.
- **Harbor design shifts:** federation is one indexer config away from off;
  wikis lose nothing (ARCHITECTURE layer separation). If the mesh proves
  awkward in practice, the fallback the operator already blessed — wiki-kit
  standalone — is the P0–P3 system unchanged.

## Fable/Opus split

Done here (Fable): the schema, grammar, caps, staleness algorithm, routing
rules, trust/visibility mapping — the judgment-dense, drift-prone decisions.
Opus work: everything above — lint implementation, skill prompts, fixtures,
pilots, rollout mechanics — plus one judgment checkpoint: after the P1
pilots, review whether the page-kind taxonomy and routing rule survived
contact with real repos, and bring any spec amendment back for review rather
than drifting the spec in place.
