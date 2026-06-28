#!/usr/bin/env node
/**
 * render-html.cjs — turn a Markdown answer/doc/plan into a self-contained styled HTML
 * file (with Mermaid diagrams rendered). Bundled per skill so it works standalone.
 *
 * Usage:
 *   node render-html.cjs <input.md> [output.html] [title]
 *   - output.html defaults to the same path with .html
 *   - prints the output path on stdout (so the skill can open it)
 */
const fs = require('fs');
const path = require('path');
const { buildDocumentHtml } = require('./html-builder.js');

const mdFile = process.argv[2];
if (!mdFile || !fs.existsSync(mdFile)) {
  console.error('usage: node render-html.cjs <input.md> [output.html] [title]');
  process.exit(1);
}
const out = process.argv[3] || mdFile.replace(/\.md$/i, '') + '.html';
const title = process.argv[4] || path.basename(mdFile).replace(/\.md$/i, '').replace(/[-_]/g, ' ');

fs.mkdirSync(path.dirname(out), { recursive: true });
fs.writeFileSync(out, buildDocumentHtml(title, fs.readFileSync(mdFile, 'utf8')), 'utf8');
console.log(out);
