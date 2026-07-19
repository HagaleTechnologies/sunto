---
name: wiki-gc
description: Use when the wiki has grown noisy — near-duplicate pages, over-cap pages,
  or deprecated pages with no inbound links (WK-L8 nearing, or on a periodic sweep).
  Merges, splits, and prunes. When in doubt, delete.
---

## wiki-gc

Garbage-collect the wiki so it stays small and trustworthy. Governing rule:
**wrong is worse than missing** — when in doubt, delete; git history preserves
everything.

**Survey the whole wiki:**
```bash
python3 <sunto>/bin/wiki-lint wiki/            # note WK-L8 / soft page-count warn
python3 <sunto>/bin/wiki-lint --manifest wiki/ # ids, kinds, sources, links
```

**Merge near-duplicates.** When two pages answer the same question:
- keep the **oldest id** (federation consumers cache by id); retire the other.
- the survivor's `sources` become the **union** of both.
- re-point every inbound `[[link]]` and `links:` entry to the survivor.
- re-stamp the survivor's `verified`.

**Split over-cap pages.** A page over 120 lines / 8 KB (WK-L3) is two pages, or
part of it is a spec that belongs in `docs/`. Split by question, not by length.

**Delete `deprecated` pages with no inbound links.** A `deprecated` page exists
only to keep links alive; once nothing links to it, remove it. Also delete any
page that is simply wrong and not worth fixing.

**Retire ids.** Never reuse the id of a deleted or merged-away page.

**Regenerate and lint clean:**
```bash
python3 <sunto>/bin/wiki-lint --index wiki/    > wiki/INDEX.md
python3 <sunto>/bin/wiki-lint --manifest wiki/ > wiki/manifest.json
python3 <sunto>/bin/wiki-lint wiki/            # must exit 0
```

**Invariants:** oldest id survives a merge; union the sources; retire deleted
ids; re-link before deleting; end lint clean.
