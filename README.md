# sunto

sunto is a per-repo **agentic knowledge wiki**: a small `wiki/` directory of
short, routed pages that agents maintain, plus a deterministic lint tool that
keeps them honest. It is a Claude Code plugin (five skills) backed by
`bin/wiki-lint` — a stdlib-only Python tool that checks, and regenerates the
manifest and index for, a repo's wiki.

The wiki **points, it never restates**: normative constants and specs live in
`docs/`/`dispensa`; wiki pages cite them. The wiki is descriptive and always
loses conflicts with code and docs.

## Quick-start

1. **Install the plugin.** Add this repo's `plugin/` via your Claude Code plugin
   marketplace, or point Claude Code at it directly.
2. **Initialize a repo's wiki.** In the target repo, run `/wiki-init`. It surveys
   the repo, proposes a 5–15 page list, writes seed pages, `wiki.toml`,
   `INDEX.md`, and `manifest.json`, and installs the CLAUDE.md stanza.
3. **Keep it fresh.** After substantive work run `/wiki-update`; adjudicate
   staleness with `/wiki-verify`; prune with `/wiki-gc`; publish with
   `/wiki-export`.
4. **Gate it in CI** with `wiki-lint` (below).

## CI recipe

`wiki-lint` exits 0 when clean, 1 on any `WK-L*` failure, 2 on usage/IO error.
Warnings (`WK-W11`/`WK-W12`, staleness) never fail CI — they are adjudicated by
`/wiki-verify`, not by whoever happens to touch a source file. Manifest freshness
(`WK-L10`) *is* a failure, like a lockfile.

```yaml
- name: Wiki lint
  run: python3 path/to/sunto/bin/wiki-lint wiki/
```

Regenerate the committed manifest/index whenever pages change:

```bash
python3 path/to/sunto/bin/wiki-lint --manifest wiki/ > wiki/manifest.json
python3 path/to/sunto/bin/wiki-lint --index    wiki/ > wiki/INDEX.md
```

`wiki-lint` modes: (default) check · `--manifest` · `--index` · `--stale`
(candidate-stale ids) · `--json` (machine-readable findings) · `--version`.

## Running tests

The fixtures double as the test suite; no third-party deps.

```bash
python3 bin/wiki-lint fixtures/wiki/        # expect exit 1 with WK-L10
python3 bin/wiki-lint --manifest fixtures/wiki/ | \
  python3 -c 'import sys,json; json.load(sys.stdin)'   # valid JSON
bash fixtures/setup.sh                       # builds a temp repo; asserts WK-W11
```

See `fixtures/README.md` for what each fixture page exercises.

## Spec version

This kit implements **wiki-kit v1** — the `wiki-manifest/v1` and
`wiki-config/v1` contracts and the restricted frontmatter grammar, together.
`wiki-lint --version` prints the spec version it enforces. See `SPEC.md` for the
normative specification.

Licensed MIT OR Apache-2.0.
