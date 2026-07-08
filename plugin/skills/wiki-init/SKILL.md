---
name: wiki-init
description: Use when starting work in a repo that has no wiki/ yet, or when asked to
  initialize the repo's sunto knowledge wiki. Surveys the repo, proposes a page list,
  and writes seed pages plus INDEX, wiki.toml, and manifest.
---

## wiki-init

Bootstrap a repo's `wiki/` from scratch. The wiki **routes, it does not copy** —
normative content stays in `docs/`/`dispensa`; the wiki holds pointer pages.

**Locate the kit.** `wiki-lint` is at `<sunto>/bin/wiki-lint` (this plugin's
repo). Templates are in `<sunto>/templates/`. If a `wiki/` already exists, stop
and suggest `/wiki-update` instead — do not re-init.

**Survey the repo** (read, do not guess):
```bash
ls -la; cat README.md 2>/dev/null; ls docs/ 2>/dev/null
cat CLAUDE.md 2>/dev/null
git log --oneline -20
```
Map the top-level code layout (crates/packages/modules), the docs surface, and
any `dispensa` contracts the repo consumes. Note the repo's license/visibility.

**Propose a page list to the user — do not write yet.** Target **5–15 pages**,
never exhaustive:
- exactly one `overview` (id `overview`, required),
- the top subsystems, the highest-value gotchas, the exposed/consumed
  interfaces, key decision-digests.
On a doc-heavy repo, most pages will be `decision-digest`/`interface` pointer
pages — that is correct, not thin. Present the list with one-line rationales and
wait for confirmation or edits.

**Write the seed pages** from `templates/pages/<kind>.md`. For each page: fill
real `id`/`title`/`sources`; set `verified.commit` to `git rev-parse --short
HEAD` and `verified.date` to today; keep bodies ≤ 120 lines / 8 KB; begin each
with the one-paragraph answer. **Never restate constants** from `docs/`/dispensa —
cite them ("window constants: SPEC-features §A2").

**Write the machinery:**
```bash
cp <sunto>/templates/wiki.toml wiki/wiki.toml   # set repo + visibility
python3 <sunto>/bin/wiki-lint --index wiki/    > wiki/INDEX.md
python3 <sunto>/bin/wiki-lint --manifest wiki/ > wiki/manifest.json
```
Set `wiki.toml` `visibility` to match the repo (public repo ⇒ `public`).

**Install the CLAUDE.md stanza.** Append the contents of
`templates/CLAUDE-stanza.md` to the repo's `CLAUDE.md` (create it if absent).

**End clean.**
```bash
python3 <sunto>/bin/wiki-lint wiki/    # must exit 0
```
Fix any WK-L* failure before finishing. Commit the wiki with the work.

**Invariants:** exactly one overview; route don't copy; propose before writing;
lint must be clean at the end.
