# sunto fixtures

A static fixture wiki plus a setup script, designed so `wiki-lint` produces a
known, checkable set of findings. Used by CI and by anyone changing the tool.

## `wiki/` — the static fixture

A complete, otherwise-clean wiki whose pages deliberately trip specific checks:

| Page | Exercises |
|---|---|
| `overview` | the required single `overview` page (WK-L6); a `crates/**/*.rs` glob source |
| `hot-loop` | designated WK-W11 page; a real path source + a `url:` source (url skipped by staleness) |
| `dsp-pipeline` | glob source `crates/skimmer-dsp/**`; a `[[hot-loop]]` link (WK-L5) |
| `config-gotcha` | `locked: true` (surfaces in the manifest) |
| `spot-format-decision` | `verified.date: 2026-01-01` → WK-W12 (older than 90 days) |
| `deploy-runbook` | a plain multi-source runbook |
| `open-detector-question` | `kind: question` with empty `sources` (the only kind allowed to) |

`manifest.json` is **deliberately wrong** (one page hash zeroed, `head_commit`
mangled) so **WK-L10** fires. The pages' `verified.commit` SHAs do not exist in
this repo, so they are also reported candidate-stale (WK-W11, unresolvable
commit) — that demonstrates the shallow/rebased-away case.

Running `wiki-lint fixtures/wiki/` therefore exits **1** on WK-L10, plus WK-W11
and WK-W12 warnings.

## `setup.sh` — real-history staleness

The static fixture cannot exercise a genuine `git diff` (its verified commits
are not real). `setup.sh` builds a throwaway repo at `/tmp/sunto-fixture-test`
with two commits: an initial commit (the verified point) and a second commit
that touches `src/hot_loop.rs`, a source of `pages/hot-loop.md`. It regenerates
the manifest/index so the only findings are staleness warnings, then asserts
**WK-W11 fires for `hot-loop`**.

```bash
bash fixtures/setup.sh
```

## How tests use these

- `python3 bin/wiki-lint fixtures/wiki/` → expect exit 1 with `WK-L10`.
- `python3 bin/wiki-lint --manifest fixtures/wiki/` → valid JSON that validates
  against `schema/wiki-manifest.v1.schema.json`; byte-identical across two runs.
- `bash fixtures/setup.sh` → exits 0 and prints `PASS: WK-W11 fired for hot-loop`.
