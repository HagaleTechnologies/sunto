# wiki-kit — Specification (v1)

**Status: normative.** Implement from this; design decisions are made. The
manifest schema and frontmatter grammar are versioned contracts — changing
either is a spec revision, not a code change. Where this spec and a repo's own
normative docs conflict about repo *content*, the repo wins; where they
conflict about *wiki mechanics*, this spec wins.

## 1. Directory contract

```
wiki/
├── INDEX.md          # required; format §4
├── wiki.toml         # required; format §7
├── manifest.json     # required in committed state; generated (§5); CI-checked fresh
└── pages/<id>.md     # zero or more; <id> = frontmatter id = filename stem
```

Nothing else may live under `wiki/`. `wiki-lint` fails on unknown files
(WK-L1). Rationale: the directory is a machine-consumed surface; stray files
break the "manifest describes everything" guarantee.

## 2. Page format

A page is UTF-8 markdown: frontmatter block, then body.

### 2.1 Frontmatter grammar (restricted, deliberately)

Frontmatter is delimited by `---` lines and uses a **restricted subset** of
YAML so a stdlib-only parser is trivial and identical everywhere:

- `key: scalar` — scalars are unquoted strings, ISO dates, booleans
  `true`/`false`. No quoting, no escapes, no multiline scalars.
- `key:` followed by `  - item` lines — flat string lists only.
- `verified:` followed by exactly two indented `key: scalar` lines
  (`commit`, `date`) — the only nested map permitted.
- No other YAML features: no anchors, no flow style, no comments, no nesting.

`wiki-lint` rejects anything outside this grammar (WK-L2). Full YAML parsers
MUST NOT be used even where available — the restricted grammar *is* the
contract, and "valid YAML that lint can't parse" must be impossible.

### 2.2 Fields

| Field | Req | Values / form | Notes |
|---|---|---|---|
| `id` | yes | kebab-case, `[a-z0-9-]{3,64}`, unique in repo | == filename stem. Global id (federation) is `<repo>/<id>`. Never reused after deletion. |
| `title` | yes | one line | The question or claim the page answers. |
| `kind` | yes | §3 enum | |
| `status` | yes | `current` \| `stale` \| `draft` \| `deprecated` | `stale` set by verify, never by update. `deprecated` = kept only because inbound links exist. |
| `maintainer` | yes | `agent` \| `human` \| `mixed` | Any human edit ⇒ at least `mixed`. |
| `locked` | no (default `false`) | bool | `true` ⇒ agents MUST NOT modify body or frontmatter except `verified` re-stamp. |
| `visibility` | no (default `repo`) | `repo` \| `public-safe` | §5. `public-safe` on a closed repo marks a page exportable anyway. There is no `private` on an open repo — if it can't be public, it can't be in an open repo's wiki at all. |
| `sources` | yes (MAY be empty only for `kind: question`) | list of repo-relative paths, optional `#fragment` | Staleness evidence. Globs allowed (`crates/skimmer-dsp/**`). External URLs allowed with `url:` prefix — excluded from staleness compute, flagged `[ext]` by lint. |
| `verified` | yes | `commit` (short SHA), `date` (ISO) | Last time an agent/human confirmed the body against the sources. |
| `links` | no | list of ids | Merged with body `[[id]]` links; lint validates both (WK-L5). |

### 2.3 Body rules

- ≤ **120 lines / ≤ 8 KB** (WK-L3). A page that wants to be bigger is two
  pages, or it's a spec that belongs in `docs/`.
- MUST begin with a one-paragraph answer/summary (the "if you read nothing
  else" paragraph — also the natural first chunk for embedding).
- Headings `##` and below; heading-structured for clean chunking.
- MUST NOT restate normative values (constants, thresholds, schema fields)
  from `docs/`/`dispensa` — cite the artifact instead ("window constants:
  SPEC-features §A2"). Lint can't check this; `/wiki-verify` and review must.
  This is the drift-bug firewall and the most important editorial rule in the
  system.
- `[[id]]` links resolve within the repo. Cross-repo references use plain
  text (`dispensa Q-0028`, `coppa's watterson.rs`) — never `[[...]]`, so
  link-checking stays local and closed-repo names don't become dependencies.

## 3. Page kinds

| kind | Answers | Typical trigger |
|---|---|---|
| `overview` | "What is this repo / subsystem-map?" | init; exactly one `overview` page named `overview` required (WK-L6) |
| `subsystem` | "How does X work and why is it shaped this way?" | init, post-implementation |
| `concept` | "What does term/idea X mean here?" | recurring confusion |
| `decision-digest` | "Why is it done this way?" — digest + pointer to ADR/spec/commit | after decisions; the normative artifact stays authoritative |
| `gotcha` | "What will bite you?" (stale assumptions, footguns, environment quirks) | the moment one costs time — highest-value kind |
| `runbook` | "How do I do routine task X?" | second time a procedure is performed |
| `interface` | "What contract does this repo expose/consume?" — pointers to schemas, dispensa ids | init, contract changes |
| `question` | "What do we not know yet?" — open question + current best understanding | when a question outlives a session |

## 4. INDEX.md format

Header line `# <repo> wiki index`, optional one-paragraph orientation, then
exactly one line per page, grouped by kind (kinds in §3 table order):

```
- [<title>](pages/<id>.md) — <hook, ≤ 100 chars> <markers>
```

Markers: `⚠stale` (status stale), `🔒` (locked), `[draft]`. INDEX is
regenerable from pages (`wiki-lint --index`) but committed, because it's the
one file agents always read — it must never require tooling to view. Lint
fails on INDEX/pages disagreement (WK-L7).

Budget: INDEX ≤ 150 lines. Soft page-count warning at 60 pages, lint failure
at 100 (WK-L8) — at that point the repo needs `/wiki-gc` or the wiki is doing
a job (spec? book?) it shouldn't.

## 5. Visibility and export

Effective visibility of a page = `public` if the repo is public, else
(`public-safe` if tagged, else `private`).

- **Placement rule (WK-L9, from `wiki.toml` `visibility`):** an open repo's
  wiki may contain only content publishable under that repo's license. No
  mechanism exists to hold private pages in a public repo — by design.
- **Export rule:** `/wiki-export` and any federation consumer include a page
  only where its effective visibility permits the destination.
- **Cross-repo rule:** wiki content is never copied between repos of
  different visibility; closed-repo knowledge is referenced from open wikis
  only as opaque pointers (dispensa Q-ids). Same boundary as propagation/cqdx.

## 6. `wiki-lint` (deterministic tool)

Python ≥ 3.10, **stdlib only**. Exit 0 clean, 1 violations, 2 usage/IO error.
Deterministic: given identical tree + HEAD, byte-identical output; all
ordering lexicographic by id; manifest serialized with sorted keys, 2-space
indent, trailing newline.

Checks (each with stable code): **WK-L1** unknown files under `wiki/`;
**WK-L2** frontmatter grammar/field validity; **WK-L3** body caps; **WK-L4**
id/filename/uniqueness; **WK-L5** broken `[[links]]`/`links:` (targets must
exist, `deprecated` targets warn); **WK-L6** overview page present; **WK-L7**
INDEX consistency; **WK-L8** page-count cap; **WK-L9** visibility placement;
**WK-L10** manifest.json out of date (committed ≠ regenerated); **WK-W11**
(warning) candidate-stale pages — sources touched since `verified.commit`;
**WK-W12** (warning) `verified.date` older than 90 days regardless of diff
(catches semantic drift in unmoved files).

Modes: `wiki-lint` (check), `--manifest` (regenerate manifest.json),
`--index` (regenerate INDEX.md), `--stale` (list candidate-stale ids for
`/wiki-verify`), `--json` (machine-readable findings).

**CI policy (normative):** WK-L* are failures; WK-W* are warnings. Staleness
must not break unrelated CI — it's adjudicated by `/wiki-verify`, not by
whoever happens to touch a source file. Manifest freshness (WK-L10) *is* a
failure, like a lockfile.

Staleness compute: `git diff --name-only <verified.commit>..HEAD`
intersected with `sources` (fragment stripped; glob and prefix match;
`url:` entries skipped). Unresolvable `verified.commit` (rebase, shallow
clone) ⇒ page is candidate-stale by definition.

## 7. wiki.toml

```toml
schema = "wiki-config/v1"
repo = "skimmer"
visibility = "public"        # public | private
# optional overrides:
# max_pages = 100
# export_max_bytes = 400000
```

## 8. Manifest (`wiki-manifest/v1`)

Generated only. JSON Schema ships in the kit (`schema/`); shape:

```json
{
  "schema": "wiki-manifest/v1",
  "repo": "skimmer",
  "visibility": "public",
  "head_commit": "<short sha>",
  "generated_at": "<ISO8601, from git HEAD commit time — NOT wall clock>",
  "pages": [
    {
      "id": "pfb-oversampling", "path": "pages/pfb-oversampling.md",
      "title": "...", "kind": "subsystem", "status": "current",
      "maintainer": "agent", "locked": false, "visibility": "public",
      "hash": "sha256:<body-only hash>",
      "verified_commit": "0b5029d", "verified_date": "2026-07-07",
      "links": ["noise-floor"], "sources": ["crates/skimmer-dsp/**"]
    }
  ]
}
```

`generated_at` derives from HEAD's commit timestamp so regeneration is
reproducible (same tree ⇒ same manifest, byte-identical — the determinism rule
tonight's other specs all carry). `hash` covers the body only (frontmatter
excluded) so a `verified` re-stamp doesn't force consumers to re-embed.
Consumers (harbor `repo-wiki` indexer, anything else) MUST key on
`(repo, id)` and re-process only on `hash` change; MUST honor `status` and
effective visibility; MUST treat all fields beyond these as informational.

## 9. Skill behavioral contracts

Skills are prompts, not code — but their *obligations* are normative:

- **`/wiki-init`**: survey repo (README, docs, CLAUDE.md, code layout, recent
  git history) → propose page list to the user → write seed pages (`overview`
  + top subsystems/gotchas/interfaces; target 5–15, never exhaustive) → INDEX,
  wiki.toml, manifest → install CLAUDE.md stanza (§10) → run lint clean.
  Init MUST route, not copy: content already normative in docs/ becomes
  pointers. On doc-heavy repos (BeatScope), init produces mostly
  `decision-digest`/`interface` pointer pages — that is correct, not thin.
- **`/wiki-update`** (the everyday verb): given the session's work, extract
  candidate knowledge; for each item apply the routing test (normative →
  docs/dispensa + pointer; covered → edit existing page; ephemeral → drop;
  else → new page). Re-stamp `verified` on any page whose sources were
  directly confirmed in-session. Never touch `locked` pages. End: lint clean,
  changes committed with the work (wiki edits ride the same commit/PR as the
  code they describe when practical).
- **`/wiki-verify`**: run `wiki-lint --stale`; for each candidate, re-read
  sources; outcome per page ∈ {re-stamp, fix + re-stamp, mark `stale`,
  delete (with INDEX cleanup)}. MUST NOT expand scope beyond candidates
  except pages hit by WK-W12.
- **`/wiki-gc`**: merge near-duplicates (union of sources, oldest id
  survives), split over-cap pages, delete `deprecated` pages with no inbound
  links, re-link. Deletion policy: **wrong is worse than missing** — when in
  doubt, delete; git history preserves. Ids of deleted pages are retired
  (never reused — federation consumers cache by id).
- **`/wiki-export`**: emit `PROJECT-DIGEST.md` (INDEX orientation + all
  `current`, visibility-permitted pages; stamped repo/commit/date; hard cap
  `export_max_bytes`, default 400 KB; over cap ⇒ drop `question`/`runbook`
  kinds first, then fail loudly rather than truncate silently).

## 10. CLAUDE.md stanza (standard text, installed by init)

```markdown
## Knowledge wiki

`wiki/INDEX.md` is the map of accumulated knowledge — read it before deep
exploration; open pages relevant to your task. After substantive work, run
/wiki-update: distill new gotchas/decisions/corrections into the wiki (or
into docs/ if normative — the wiki points, it never restates). The wiki is
descriptive and always loses conflicts with code and docs/.
```

## 11. Versioning

`wiki-manifest/v1`, `wiki-config/v1`, and the frontmatter grammar version
together as **wiki-kit v1**. Additive optional fields are minor; anything a
v1 consumer would misread is v2, and manifests carry the schema string so
consumers can refuse what they don't understand. `wiki-lint --version`
reports the spec version it enforces.
