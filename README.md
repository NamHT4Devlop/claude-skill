# Spec Kit for Claude Code

A native **Claude Code** port of the [Auto Spec Kit](../auto-spec-extension) VS Code
extension. Same spec-driven workflow — **Requirement → Plan → Code → Review → Test →
Evidence** — plus Knowledge Base generation, codebase Q&A, user stories, dependency mapping,
and business↔code documentation. The difference: it runs on **Claude Code** (your own
tools: file ops, Bash, git, parallel sub-agents) instead of GitHub Copilot / `vscode.lm`.

> **Your existing Knowledge Bases work as-is.** The KBs you generated with the old extension
> are plain Markdown under each repo's `knowledge-base/`. Every command here reads that same
> folder — nothing to migrate or regenerate. Only run `/spec-kit:scan` for brand-new repos.

---

## What's inside

```
claude-skill/
├── .claude-plugin/
│   ├── plugin.json          # plugin manifest
│   └── marketplace.json     # local marketplace (for one-command install)
├── commands/                # 9 slash commands → /spec-kit:build, :scan, :review, …
├── skills/                  # 8 skills (the methodology — also usable standalone)
│   ├── spec-build/          #   13-step pipeline   (+ bundled review checklist)
│   ├── spec-scan/           #   KB generation       (+ bundled kb-steps spec)
│   ├── spec-rescan/         #   incremental KB update
│   ├── spec-review/         #   two-phase review    (+ bundled review checklist)
│   ├── spec-ask/            #   KB-grounded Q&A
│   ├── spec-plan/           #   PO/BA user stories
│   ├── spec-map/            #   dependency graph → Mermaid
│   └── spec-document/       #   business↔code doc
├── agents/                  # 7 specialist sub-agents (planning + review)
└── resources/               # review-skills-universal.md, kb-steps.md
```

Commands are thin entry points; the **skills** hold the actual methodology and auto-activate
from natural language too (you don't have to type the slash command). The **agents** are the
read-only specialists the build/review steps fan out to in parallel.

---

## Install — Option A: as a plugin (recommended)

Use this when you want it available across **all** your repos on this machine.

From a Claude Code session (in any project):

```
/plugin marketplace add /Users/MAC/AI-TOOL/claude-skill
/plugin install spec-kit@spec-kit-marketplace
```

Then restart/reload when prompted. Commands appear as `/spec-kit:build`, `/spec-kit:scan`,
`/spec-kit:review`, `/spec-kit:ask`, `/spec-kit:plan`, `/spec-kit:map`, `/spec-kit:document`,
`/spec-kit:rescan`, `/spec-kit:help`. The bundled skills and agents are loaded automatically.

> The marketplace `source` is `./`, so adding this folder registers the plugin that lives in
> the same folder. You can keep this directory under version control and `add` it on any machine.

## Install — Option B: plain skills (per-repo or per-user)

Use this if you prefer raw skills without the plugin/marketplace machinery, or want to commit
the skills into a specific project.

- **Per project** — copy the skills (and optionally commands/agents) into the repo's `.claude/`:
  ```
  cp -R /Users/MAC/AI-TOOL/claude-skill/skills/*   <your-repo>/.claude/skills/
  cp -R /Users/MAC/AI-TOOL/claude-skill/commands/* <your-repo>/.claude/commands/
  cp -R /Users/MAC/AI-TOOL/claude-skill/agents/*   <your-repo>/.claude/agents/
  ```
- **For all your repos (user-level)** — copy into `~/.claude/` instead:
  ```
  cp -R /Users/MAC/AI-TOOL/claude-skill/skills/*   ~/.claude/skills/
  cp -R /Users/MAC/AI-TOOL/claude-skill/commands/* ~/.claude/commands/
  cp -R /Users/MAC/AI-TOOL/claude-skill/agents/*   ~/.claude/agents/
  ```

Each skill is self-contained — `spec-build`/`spec-review` bundle the review checklist and
`spec-scan`/`spec-rescan` bundle the KB-section spec under their own `references/`, so they
work even without the plugin's shared `resources/`. (As plain skills, commands aren't
namespaced — they're `/build`, `/review`, etc. Rename if they clash with other commands.)

---

## Commands

| Command | What it does |
|---------|--------------|
| `/spec-kit:scan` | Generate the Knowledge Base from the codebase (16 docs + `review-skills.md` + per-module docs). Run first on a new repo. |
| `/spec-kit:rescan` | Update the KB incrementally after code changes (git-diff aware). |
| `/spec-kit:build <requirement>` | 13-step pipeline: clarify → plan (impact + business flow) → code → multi-lens review → tests → run tests → evidence → update KB. |
| `/spec-kit:review [file]` | Two-phase review: quality checklist + business consistency vs the KB. Empty arg = current diff. |
| `/spec-kit:ask <question>` | Q&A grounded in the KB — plain language + Mermaid diagram + technical detail. |
| `/spec-kit:plan <epic>` | PO/BA: Epic → features → impact → user stories (Given/When/Then) → sprint plan. |
| `/spec-kit:map [scope]` | Dependency graph (imports/DI/calls/inheritance) → Mermaid, enriched with business meaning. |
| `/spec-kit:document <topic>` | Business↔code field-level technical document for a feature/entity/module. |
| `/spec-kit:help` | Show all commands + KB status for the current repo. |

**Recommended flow:** `scan` once → `ask` / `map` / `document` to understand → `plan` to break
down work → `build` to implement → `rescan` to keep the KB fresh.

---

## How this maps to the original extension

| Auto Spec Kit (VS Code + Copilot) | Spec Kit for Claude Code |
|-----------------------------------|--------------------------|
| `vscode.lm` calls to Copilot | Claude Code itself (no external API key) |
| `agent-orchestrator` parallel sub-agents | `Task` tool fan-out to the `agents/` specialists |
| Emits ```### FILE:``` code blocks to copy | Applies changes directly with Edit/Write |
| `testCommand` run by the extension | `Bash` runs the project's test command |
| Session outputs in `spec-kit-sessions/` | Same — artifacts saved per run |
| `knowledge-base/` (16 docs + review-skills + modules) | **Identical format — reused as-is** |
| Webview HTML (ask/plan/document/map) | Markdown + Mermaid (renders anywhere; HTML on request) |

### Not ported (and why)
- The VS Code UI bits (Quick Picks, webviews, keybindings, output channel) — Claude Code is
  the UI now. Q&A/plans/docs are returned as Markdown + Mermaid; ask for HTML if you want it.
- Token-budget/throttling/checkpoint-resume plumbing — Claude Code manages context and tools
  natively, so the methodology is preserved without the bespoke machinery.

---

## Notes
- Every command degrades gracefully if a repo has no `knowledge-base/` — it'll read source
  directly and suggest running `/spec-kit:scan`, but results are richer with a KB.
- `build` and `review` enforce the **"Architecture Invariants — DO NOT BREAK"** list from
  `knowledge-base/16-architecture-patterns.md` and the rules in `knowledge-base/review-skills.md`.
- Source of truth for the methodology: the original prompts in
  `../auto-spec-extension/src/` (pipeline steps, `constants/kb-steps.ts`,
  `resources/review-skills-universal.md`).
