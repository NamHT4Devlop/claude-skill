---
name: namht-pdf
description: >-
  Export a report to PDF — take a Markdown or HTML file (e.g. a Spec Kit
  report/doc under spec-kit-sessions/, or any .md) and produce a PDF, rendering
  Markdown + Mermaid first if needed. Use when the user says "/pdf", "export to
  PDF", "make a PDF", "save this as PDF", "PDF the report/doc".
---

# namht-pdf — export a report/doc to PDF

(Adapted from gstack's make-pdf idea, MIT.) Turn a Markdown or HTML report into a shareable PDF.

## Steps
1. **Resolve the input.** If given a `.md`, first render it to a self-contained HTML with the
   bundled renderer (Mermaid drawn):
   `node "$HOME/.claude/skills/namht-pdf/references/render-html.cjs" <in.md> <tmp.html> "<title>"`
   If given an `.html`, use it directly.
2. **Convert to PDF** (best-effort, no network):
   `bash "$HOME/.claude/skills/namht-pdf/references/html-to-pdf.sh" <in.html> <out.pdf>`
   It prints the PDF path on success.
3. **Open it** (`open` / `xdg-open` / `start`) and give the user the path.

## If no converter is available
The script prints `NO_PDF_TOOL` when neither headless Chrome/Chromium/Edge nor `wkhtmltopdf` is
found. In that case: keep the HTML and tell the user to **open it in a browser → Print → Save as
PDF** (one step), or install one converter. Don't fail silently.

## Notes
- 100% local — no upload/network. Output beside the source (or under `spec-kit-sessions/`); both are
  gitignored so nothing lands in a repo.
- Works great on the outputs of `/namht-document`, `/namht-qa`, `/namht-security-audit`,
  `/namht-plan`, `/namht-retro`, etc.
