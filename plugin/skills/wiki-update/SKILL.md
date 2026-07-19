---
name: wiki-update
description: The everyday verb. Use after substantive work in a repo with a wiki/ to
  distill new gotchas, decisions, and corrections into the wiki. Applies the routing
  test, re-stamps verified pages, and ends with a clean lint.
---

## wiki-update

Fold what this session learned into the wiki. Bias toward small, correct edits;
**wrong is worse than missing**.

**Read the map first.** Open `wiki/INDEX.md` and any pages your work touched.

**Extract candidate knowledge** from the session: new gotchas discovered,
decisions made, corrections to prior understanding, new/changed interfaces.

**Apply the routing test to each candidate:**
- **normative** (a constant, threshold, schema field, protocol rule) → it
  belongs in `docs/`/`dispensa`; put it there and leave a *pointer* page (or
  edit an existing pointer). Never restate the value in the wiki.
- **already covered** by an existing page → edit that page.
- **ephemeral** (true only for this session/branch) → drop it.
- **otherwise** → create a new page from the matching `templates/pages/<kind>.md`.

**Re-stamp `verified`** on any page whose sources you *directly confirmed*
against the code this session: set `verified.commit` to the current short HEAD
and `verified.date` to today. Do not re-stamp pages you did not actually check.

**Never touch `locked: true` pages** except to re-stamp `verified`.

**Regenerate and lint clean:**
```bash
python3 <sunto>/bin/wiki-lint --index wiki/    > wiki/INDEX.md
python3 <sunto>/bin/wiki-lint --manifest wiki/ > wiki/manifest.json
python3 <sunto>/bin/wiki-lint wiki/            # must exit 0
```

**Commit with the work.** Wiki edits ride the same commit/PR as the code they
describe whenever practical, so knowledge and code move together.

**Invariants:** route don't copy; never restate normative values; never edit
locked bodies; only re-stamp what you verified; end lint clean.
