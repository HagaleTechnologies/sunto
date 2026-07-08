---
name: wiki-verify
description: Use to adjudicate candidate-stale wiki pages — after wiki-lint reports
  WK-W11/WK-W12, or on a periodic sweep. Re-reads sources for each candidate and
  re-stamps, fixes, marks stale, or deletes. Does not expand scope.
---

## wiki-verify

Resolve staleness deliberately, one candidate at a time. Staleness is a
signal to *check*, not proof of wrongness.

**Get the candidate list — nothing more:**
```bash
python3 <sunto>/bin/wiki-lint --stale wiki/
```
This lists ids flagged by WK-W11 (sources touched since `verified.commit`) and
WK-W12 (`verified.date` older than 90 days). **Do not expand scope beyond these
candidates** (plus WK-W12 hits) — a verify pass is not a rewrite pass.

**For each candidate, re-read its `sources` against the current code**, then pick
exactly one outcome:
- **re-stamp** — page still correct: set `verified.commit` to current short
  HEAD and `verified.date` to today.
- **fix + re-stamp** — page drifted but is salvageable: correct the body (still a
  pointer, never a restatement), then re-stamp.
- **mark `stale`** — you cannot confirm it now and it needs real work: set
  `status: stale` (this is the *only* place `stale` is set — `/wiki-update`
  never sets it). It stays visible with the ⚠stale marker.
- **delete** — the page is wrong or obsolete: remove it and clean its INDEX line
  and any inbound links. Its id is retired, never reused.

**Never touch `locked: true` pages** except to re-stamp `verified`.

**Regenerate and lint clean:**
```bash
python3 <sunto>/bin/wiki-lint --index wiki/    > wiki/INDEX.md
python3 <sunto>/bin/wiki-lint --manifest wiki/ > wiki/manifest.json
python3 <sunto>/bin/wiki-lint wiki/
```

**Invariants:** scope = candidates only; `stale` is set here and only here;
retire deleted ids; end with regenerated INDEX + manifest.
