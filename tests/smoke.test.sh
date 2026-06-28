#!/usr/bin/env bash
# Smoke tests for the bundled Node tools: render-html (md→HTML) and build-map (code→graph HTML).
set -uo pipefail
cd "$(dirname "$0")/.."
TMP=$(mktemp -d); trap 'rm -rf "$TMP"' EXIT
fail=0

echo "smoke: render-html.cjs"
printf '# Title\n\nhello **world** and a list:\n- one\n- two\n' > "$TMP/a.md"
node resources/render-html.cjs "$TMP/a.md" "$TMP/a.html" "Smoke" >/dev/null 2>&1
if grep -q "<html" "$TMP/a.html" && grep -q "hello" "$TMP/a.html"; then echo "  ✓ render-html produced HTML"; else echo "  ✗ render-html failed"; fail=1; fi

echo "smoke: build-map.cjs"
mkdir -p "$TMP/proj/src"
printf "import { b } from './b';\nexport function a() { return b(); }\n" > "$TMP/proj/src/a.ts"
printf "export function b() { return 1; }\n" > "$TMP/proj/src/b.ts"
node skills/namht-map/references/build-map.cjs "$TMP/proj" "$TMP/map.html" all >/dev/null 2>&1
if grep -q 'id="graph-data"' "$TMP/map.html" && grep -q '"nodes"' "$TMP/map.html"; then echo "  ✓ build-map produced graph HTML"; else echo "  ✗ build-map failed"; fail=1; fi

echo "smoke: $([ "$fail" -eq 0 ] && echo PASS || echo FAIL)"
[ "$fail" -eq 0 ]
