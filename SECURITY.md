# Security & Enterprise Notes — `claude-skill`

This document is for a security reviewer evaluating whether to use this toolkit on a
company machine. It describes exactly what the code does, what it does **not** do, and how to
verify it yourself.

## TL;DR
- The executable code is **pure local** (Node `fs` / `path` / `crypto` only). **No shell exec,
  no `eval`, no dynamic `require`, no network calls, no secrets.** Safe to copy and run locally.
- The only external dependency is **at view-time**: generated HTML can load a JS chart library
  (Mermaid/Cytoscape) from a CDN — and even that is **eliminated** when the bundled `vendor/`
  libraries are present (default in this repo → fully offline, self-contained HTML).
- It contains **no credentials**. It does not phone home. Telemetry is not part of this repo
  (that belongs to the separate CodeGraph tool — disable with `codegraph telemetry off`).

## What's in the repo
| Type | Files | Risk |
|------|-------|------|
| Skill / command / agent prompts | `skills/`, `commands/`, `agents/` (Markdown) | Instructions for the AI; reviewed below |
| Static code analyzer | `skills/namht-map/references/graph-builder.js` | Reads source files, builds a graph. `fs`/`path` only |
| HTML renderers | `skills/*/references/html-builder.js` + `render-html.cjs`, `build-map.cjs` | Markdown/graph → HTML. `fs`/`path`/`crypto` only |
| Vendored JS libs | `vendor/mermaid.min.js`, `vendor/cytoscape.min.js` | Upstream OSS, inlined into HTML for offline render |
| Install scripts | `scripts/personal-install.sh`, `scripts/onboard-project.sh` | Symlink into `~/.claude`; write `.gitignore`/`CLAUDE.md` |

## Executable-surface audit (verify it yourself)
```bash
# 1) No shell-out / eval / dynamic require / network in any JS or shell file:
grep -rnE "child_process|execSync|spawn|\beval\(|new Function|http\.|https\.|fetch\(|net\.|dns\." \
  --include='*.js' --include='*.cjs' --include='*.sh' .
#   → only matches should be RegExp.exec(...) (string matching) — not process execution.

# 2) Real require()s are stdlib + local siblings only:
grep -rnE "require\((['\"])" --include='*.js' --include='*.cjs' .   # fs, path, crypto, ./html-builder, ./graph-builder

# 3) No secrets committed:
grep -rniE "api[_-]?key|secret|password|BEGIN (RSA|PRIVATE)|sk-|ghp_|AKIA[0-9A-Z]{16}" .
#   → only the WORD "secret/token" in review checklists, no actual values.
```
Findings (as audited): no shell execution, no `eval`/`Function`, no dynamic `require`, no network
calls, no hardcoded secrets. `graph-builder.js`/`html-builder.js` are readable `tsc` output (not
minified) — provenance: the author's own `auto-spec-extension` repo.

## Data flow & egress
- **CodeGraph / KB / analyzer**: 100% local. The graph index and `knowledge-base/` never leave
  the machine.
- **The real egress is the AI agent itself**: when Claude reads code (via `Read` or
  `codegraph_explore`), that source enters the LLM context (Anthropic). This is inherent to using
  an AI coding assistant — **not added by this toolkit**. It is acceptable under a company
  **Team/Enterprise** Claude plan (commercial terms; Anthropic does not train on your data by
  default). Confirm your plan tier with your admin.
- **Generated HTML**: graph/markdown data is embedded **inline**. With `vendor/` present, the
  chart library is inlined too → the HTML makes **zero external network requests**. Without
  `vendor/`, it links Mermaid/Cytoscape from `cdnjs.cloudflare.com` at view-time (no data sent;
  may be blocked by a strict proxy). Delete `vendor/` for the small CDN-linked output, keep it
  for offline/air-gapped.

## Install-script safety
- `personal-install.sh` only creates symlinks under `~/.claude/{skills,commands,agents}` and, on
  uninstall, **only removes symlinks whose target points back into this repo** (`case "$SRC"/*`).
  It cannot delete arbitrary files.
- `onboard-project.sh` **writes into a target project** (`.gitignore` += `spec-kit-sessions/`,
  and a starter `CLAUDE.md` if absent). Do **not** run it on a shared/team repo if you want zero
  footprint — review its diff first.

## Built-in safety behavior (prompts)
- `namht-build` / `namht-review` enforce a **change-discipline contract**: scope-locked, minimal
  diff, no drive-by refactors, don't leave the build broken (verify + rollback), confirm before
  destructive/outward actions, never touch secrets.
- `namht-scan` skips secret files and records that a secret exists, never its value.
- All tool calls (Bash, Edit, installs) remain gated by Claude Code's permission system — the
  user approves them. Use an **untrusted workspace** until you trust a repo.

## Recommended enterprise hardening
1. Use a company **Team/Enterprise** Claude plan (not a personal consumer plan).
2. Install CodeGraph via a **pinned npm version** or build from source (instead of `curl | sh`),
   from an internal mirror; run `codegraph telemetry off`.
3. Keep `vendor/` so generated HTML is fully offline.
4. Keep secrets out of repos (the toolkit won't index raw secret files, but config source files
   are read like any other code).
5. Have your security team skim `graph-builder.js` / `html-builder.js` (readable JS) and the two
   shell scripts — they are short.

_Not a substitute for your own security review. This reflects the state of the repo at audit time._
