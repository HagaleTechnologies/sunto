# wiki-kit — Agentic Knowledge Wiki for Every Repo and Project

*Proposal, 2026-07-07. Working name `wiki-kit`; suggested repo name **`ricettario`**
(recipe book — the pantry is `dispensa`, the accumulated knowledge is the recipe
collection). Tony's call.*

## What this is

A reusable system, in the spirit of Karpathy's agentic-wiki idea, where agents
**accumulate durable, interlinked knowledge as a side effect of doing work**.
Every repo gets a `wiki/` of small markdown pages that agents read before
exploring and update after substantive sessions. The wiki is descriptive,
evidence-anchored, and machine-checkable for staleness — not documentation you
write, but knowledge that condenses out of work.

One kit (schema + skills + lint + export tooling), rolled out identically to
every Claude Code repository and, via an export surface, to every claude.ai
Project.

## Why now

Tonight's sessions made the gap concrete. The session that designed skimmer /
propagation / BeatScope fault-detection produced excellent *deliberate*
artifacts (specs, ADRs, review findings) — but everything that wasn't worth a
spec died with the context window, and we spent real effort at session end
asking "what's still only in our head?" A wiki makes that question obsolete:
distillation is continuous, not a session-end scramble.

The auto-memory directory partially fills this role but is per-machine,
per-project-path, not in git, not visible to collaborators or other agents, and
Tony has said explicitly the repos are the durable home. The wiki is the
in-repo, versioned, shareable replacement for the knowledge layer of memory
(memory keeps only the *pointer* layer: who Tony is, workflow preferences).

## What it is NOT — boundaries with existing systems

This framework only works if it refuses to absorb its neighbors:

| System | Role | Wiki relationship |
|---|---|---|
| Code | Ground truth | Wiki always loses conflicts. Pages cite code as evidence. |
| `docs/` specs, ADRs | **Normative**, deliberately authored | Wiki is **descriptive** and regenerable. It digests and points to specs; it never restates normative constants (drift risk — tonight's review found exactly this class of bug between parallel-authored docs). |
| `dispensa` | Cross-repo contracts between pancetta/coppa/cqdx | Stays the only home for cross-repo *obligations*. Wiki pages reference `Q-NNNN`/ADR ids; they never copy cross-repo agreements in. |
| `CLAUDE.md` | Always-loaded operating instructions, small | Gets a short standard stanza pointing at `wiki/INDEX.md`. Deep knowledge moves out of CLAUDE.md into the wiki over time. |
| Auto-memory (`~/.claude/.../memory/`) | Session-to-session pointers about Tony and workflow | Keeps user/feedback facts only. Project knowledge migrates to repo wikis. |

Rule of thumb: **normative content is authored; descriptive content is
distilled.** The wiki holds only the second kind.

## Core properties

1. **Evidence-anchored.** Every page lists the source paths its claims rest on
   and the commit at which they were last verified. Staleness is then a
   *computation* (`git diff --name-only <verified>..HEAD` ∩ sources), not an
   opinion. This is the load-bearing design decision — without it, agent-written
   docs rot invisibly, which is worse than no docs.
2. **Wrong is worse than missing.** Hard size caps, aggressive deletion, a
   garbage-collection pass. Git history preserves anything deleted.
3. **One question per page.** Grain: "a question a future agent would otherwise
   burn 20 minutes of exploration answering." Linked Obsidian-style `[[id]]`.
4. **Human edits win.** Pages carry a maintainer field; `locked: true` pages are
   read-only to agents.
5. **Visibility-safe.** A page must be publishable at its own repo's license
   visibility. Closed-repo knowledge (cqdx) never gets copied into open repos'
   wikis (propagation, skimmer) — pointers via dispensa ids only. Same boundary
   discipline as the propagation/cqdx split.
6. **Interop-first — harbor meshes cleanly.** A generated `wiki/manifest.json`
   (stable ids, content hashes, kinds, staleness status, visibility) makes
   every wiki mechanically consumable. The harbor artifacts confirm the fit:
   harbor's curated-knowledge plane (hearth-vault) is already Obsidian-style
   markdown, PR-gated, chunked into pgvector by an indexer. A repo wiki is the
   same artifact class under the same discipline, so each wiki federates as a
   **read-only vault shard** — harbor's indexer gains one source type
   (`repo-wiki`), routes manifest visibility onto its namespaces, applies its
   own trust policy, and re-embeds incrementally by content hash. Write-back
   from harbor happens only as PRs (its existing `propose_edit`/INV-3
   pattern). Dependency points one way: wiki-kit never learns about harbor.

## Rollout shape

- **Claude Code repos:** wiki-kit ships as a Claude Code plugin (skills +
  templates + lint). Per-repo adoption = run `/wiki-init`, commit, add the
  CLAUDE.md stanza. Knowledge then accrues via `/wiki-update` after substantive
  work and a periodic gardener pass (`/wiki-verify` + `/wiki-gc`).
- **claude.ai Projects:** repos synced via the GitHub integration expose
  `wiki/` directly as project knowledge; for projects without a repo, or where
  sync is undesirable, `/wiki-export` builds a single size-capped
  `PROJECT-DIGEST.md` for upload.
- **Global layer (harbor):** harbor's vault indexer ingests every
  `wiki/manifest.json` as a `repo-wiki` source, giving one private cross-repo
  knowledge index with retrieval via `home/embed`/`home/rerank`. Because that
  index is argus-scoped it MAY ingest closed repos (cqdx → `private:argus`);
  the visibility rule constrains *copying between repos*, not the private
  global index. Blocked only on harbor P3 (vault + indexer live).

## Success criteria

- A fresh agent in any adopted repo answers "how does X work / why is Y like
  this" from the wiki without re-exploration, measurably faster than today.
- `wiki-lint` runs clean in CI: no schema violations, no stale-and-unflagged
  pages, no broken `[[links]]`, no cap violations.
- After a month of use, session-end "persist everything important" sweeps find
  nothing that isn't already in a repo — the scramble this proposal exists to
  eliminate.
