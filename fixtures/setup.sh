#!/usr/bin/env bash
# Build a throwaway git repo whose history makes WK-W11 fire deterministically.
#
# The static fixture in fixtures/wiki/ cannot exercise real staleness on its own
# (its verified.commit SHAs do not exist in this repo). This script materializes
# a repo with two commits: an initial commit (the "verified" point) and a second
# commit that touches a source file referenced by pages/hot-loop.md. After it
# runs, `wiki-lint` on the temp repo reports WK-W11 for hot-loop.
#
# Usage: bash fixtures/setup.sh   (then it runs wiki-lint and asserts WK-W11).
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KIT_ROOT="$(cd "$HERE/.." && pwd)"
LINT="$KIT_ROOT/bin/wiki-lint"
WORK="/tmp/sunto-fixture-test"

rm -rf "$WORK"
mkdir -p "$WORK"
cd "$WORK"

git init -q
git config user.email fixture@example.com
git config user.name "Fixture Bot"

# Materialize the wiki and the source tree its pages reference.
mkdir -p wiki src
cp -R "$HERE/wiki/." wiki/
printf 'fn hot_loop() { /* v1 */ }\n' > src/hot_loop.rs

git add -A
git commit -q -m "initial: fixture wiki + sources"
OLD="$(git rev-parse --short HEAD)"

# Re-stamp every page's verified.commit to the initial commit so it resolves,
# then touch only hot-loop's source in the next commit.
for page in wiki/pages/*.md; do
  # portable in-place sed (GNU + BSD)
  sed "s/^  commit: .*/  commit: $OLD/" "$page" > "$page.tmp" && mv "$page.tmp" "$page"
done
printf 'fn hot_loop() { /* v2 — touched */ }\n' > src/hot_loop.rs

# Regenerate manifest + INDEX so the only findings are the staleness warnings.
python3 "$LINT" --manifest wiki/ > wiki/manifest.json
python3 "$LINT" --index wiki/ > wiki/INDEX.md

git add -A
git commit -q -m "touch src/hot_loop.rs after verified commit"

echo "== temp repo: $WORK (OLD=$OLD, HEAD=$(git rev-parse --short HEAD)) =="
echo "== wiki-lint --stale =="
python3 "$LINT" --stale wiki/
echo "== wiki-lint (check) =="
set +e
python3 "$LINT" wiki/
LINT_RC=$?
set -e

if python3 "$LINT" wiki/ | grep -q "WK-W11 .*hot-loop"; then
  echo "PASS: WK-W11 fired for hot-loop"
else
  echo "FAIL: WK-W11 did not fire for hot-loop" >&2
  exit 1
fi
echo "lint exit code was $LINT_RC (warnings do not fail; 0 expected here)"
