#!/usr/bin/env bash
# html-to-pdf.sh — best-effort HTML -> PDF (headless Chrome, else wkhtmltopdf).
# Usage: html-to-pdf.sh <input.html> [output.pdf]   (prints the PDF path, or NO_PDF_TOOL to stderr)
set -euo pipefail
IN="${1:?usage: html-to-pdf.sh <input.html> [output.pdf]}"
OUT="${2:-${IN%.*}.pdf}"
[ -f "$IN" ] || { echo "input not found: $IN" >&2; exit 1; }
abs() { case "$1" in /*) printf '%s' "$1";; *) printf '%s/%s' "$PWD" "$1";; esac; }
INABS="$(abs "$IN")"; OUTABS="$(abs "$OUT")"
mkdir -p "$(dirname "$OUTABS")"

# 1) wkhtmltopdf if available
if command -v wkhtmltopdf >/dev/null 2>&1; then
  wkhtmltopdf --enable-local-file-access "$INABS" "$OUTABS" >/dev/null 2>&1 && { echo "$OUTABS"; exit 0; }
fi

# 2) headless Chrome/Chromium (covers mermaid via JS render in modern Chrome)
for c in "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" \
         "/Applications/Chromium.app/Contents/MacOS/Chromium" \
         "/Applications/Microsoft Edge.app/Contents/MacOS/Microsoft Edge" \
         google-chrome google-chrome-stable chromium chromium-browser microsoft-edge; do
  if command -v "$c" >/dev/null 2>&1 || [ -x "$c" ]; then
    "$c" --headless=new --disable-gpu --virtual-time-budget=4000 --print-to-pdf="$OUTABS" "file://$INABS" >/dev/null 2>&1 \
      || "$c" --headless --disable-gpu --print-to-pdf="$OUTABS" "file://$INABS" >/dev/null 2>&1 || true
    [ -s "$OUTABS" ] && { echo "$OUTABS"; exit 0; }
  fi
done

echo "NO_PDF_TOOL" >&2
exit 2
