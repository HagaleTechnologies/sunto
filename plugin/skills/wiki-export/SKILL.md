---
name: wiki-export
description: Use to produce a single shareable PROJECT-DIGEST.md from the wiki — for
  handoff, federation, or publishing. Emits INDEX orientation plus all current,
  visibility-permitted pages, honoring the export byte cap.
---

## wiki-export

Emit `PROJECT-DIGEST.md`: one self-contained file a human or another repo can
read without the tooling. Fail loudly rather than ship a silently truncated or
over-permissive digest.

**Read config and manifest:**
```bash
python3 <sunto>/bin/wiki-lint --manifest wiki/
cat wiki/wiki.toml   # repo, visibility, optional export_max_bytes
```
`export_max_bytes` defaults to **400000** (400 KB).

**Select pages.** Include a page only if **both**:
- `status: current` (skip `draft`, `stale`, `deprecated`), **and**
- effective visibility permits the destination. Effective visibility = `public`
  if the repo is public; else `public-safe` if the page is tagged so; else
  `private` (never exported). Never export a `private` page from a closed repo,
  and never copy content across a visibility boundary — closed-repo knowledge is
  referenced as opaque pointers only.

**Assemble the digest**, in INDEX kind order:
1. Header stamped with repo name, short HEAD commit, and today's date.
2. The INDEX orientation paragraph.
3. Each selected page: its title as a heading, then its body.

**Enforce the byte cap.** If the assembled digest exceeds `export_max_bytes`:
- first drop `question` pages, then `runbook` pages;
- if it still exceeds the cap, **fail loudly** and report which pages overflow —
  do **not** truncate silently.

Write `PROJECT-DIGEST.md` at the repo root (or the path the user names).

**Invariants:** current + visibility-permitted only; never cross a visibility
boundary; stamp repo/commit/date; drop question→runbook before failing; never
truncate silently.
