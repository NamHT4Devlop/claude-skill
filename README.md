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

## Prerequisites

- **Claude Code** installed and working (`claude --version`). Plugins/marketplaces need a
  recent version — if `/plugin` is unknown, update Claude Code first (`claude update` or
  reinstall from the official docs).
- **git** installed (`git --version`) — needed to clone this repo and used by `rescan`/`review`.
- **Access to this repository.** It is currently **private**, so cloning requires that your
  GitHub account has access (or ask the owner to add you / make it public). The plugin itself
  needs **no API key** — it runs on your existing Claude Code.
- Paths below use `~/.claude` (macOS/Linux). On **Windows** use `%USERPROFILE%\.claude`
  (PowerShell: `$HOME\.claude`).

---

## Get the code

Pick a stable location to keep the plugin (so you can update it with `git pull` later):

```bash
# via SSH (recommended if your GitHub uses SSH keys)
git clone git@github.com:NamHT4Devlop/claude-skill.git ~/claude-skill

# or via HTTPS
git clone https://github.com/NamHT4Devlop/claude-skill.git ~/claude-skill
```

Everywhere below, `<PLUGIN_DIR>` means the folder you cloned into (e.g. `~/claude-skill`).
If you keep the files somewhere else, substitute that absolute path.

---

## Install — Option A: as a plugin (recommended)

Best when you want every command available across **all** your repos on a machine, with the
nice `/spec-kit:*` namespacing. Run these **inside a Claude Code session** (the `/plugin`
commands are typed into Claude Code, not your shell):

```
/plugin marketplace add ~/claude-skill
/plugin install spec-kit@spec-kit-marketplace
```

- `marketplace add <PLUGIN_DIR>` registers the local marketplace defined in
  `.claude-plugin/marketplace.json`. You can also point it straight at the GitHub repo:
  `/plugin marketplace add NamHT4Devlop/claude-skill` (Claude Code clones it for you; requires
  repo access).
- `install spec-kit@spec-kit-marketplace` installs the plugin named `spec-kit` from that
  marketplace.
- Reload when prompted (or run `/plugin` to manage installed plugins).

After install you'll have these commands (type `/` to see them):
`/spec-kit:scan`, `/spec-kit:rescan`, `/spec-kit:build`, `/spec-kit:review`, `/spec-kit:ask`,
`/spec-kit:plan`, `/spec-kit:map`, `/spec-kit:document`, `/spec-kit:help`. The 8 skills and 7
sub-agents load automatically — skills also activate from plain English (you don't have to
type the slash command).

> **Team install:** commit/host this repo, then each teammate runs the two `/plugin` commands
> above pointing at their clone (or at `NamHT4Devlop/claude-skill`). To pin the plugin for a
> whole project automatically, add it to the project's `.claude/settings.json` under
> `enabledPlugins` / configure a marketplace there (see Claude Code plugin docs).

## Install — Option B: plain skills (no plugin machinery)

Best when you want to **commit the skills into a specific repo** (so collaborators get them on
clone), or you prefer not to use marketplaces.

**B1 — Per project** (only that repo gets the commands/skills):

```bash
# run from the target repo's root
mkdir -p .claude/skills .claude/commands .claude/agents
cp -R <PLUGIN_DIR>/skills/*   .claude/skills/
cp -R <PLUGIN_DIR>/commands/* .claude/commands/
cp -R <PLUGIN_DIR>/agents/*   .claude/agents/
```

**B2 — Per user** (all your repos on this machine):

```bash
mkdir -p ~/.claude/skills ~/.claude/commands ~/.claude/agents
cp -R <PLUGIN_DIR>/skills/*   ~/.claude/skills/
cp -R <PLUGIN_DIR>/commands/* ~/.claude/commands/
cp -R <PLUGIN_DIR>/agents/*   ~/.claude/agents/
```

Each skill is self-contained — `spec-build`/`spec-review` bundle the review checklist and
`spec-scan`/`spec-rescan` bundle the KB-section spec under their own `references/`, so they
work without the plugin's shared `resources/`.

> ⚠️ **Difference from Option A:** as plain skills the slash commands are **not** namespaced —
> they're `/build`, `/review`, `/scan`, etc. If those names clash with other commands you have,
> rename the files in `.claude/commands/` (e.g. `build.md` → `spec-build.md`).

---

## Verify the install

1. In a Claude Code session, type `/` and confirm the `spec-kit:` commands (Option A) or
   `/build`, `/scan`… (Option B) appear.
2. Run `/spec-kit:help` (or `/help` for plain skills) — it prints all commands **and** checks
   whether the current repo has a `knowledge-base/`.
3. Plugin only: run `/plugin` → you should see **spec-kit** listed as installed/enabled.

## Update to the latest version

- **Option A (plugin):**
  ```bash
  cd <PLUGIN_DIR> && git pull
  ```
  then in Claude Code: `/plugin marketplace update spec-kit-marketplace` (or remove & re-add
  the marketplace, then reinstall). Reload when prompted.
- **Option B (plain skills):** `git pull` in `<PLUGIN_DIR>`, then re-run the `cp -R` commands
  to overwrite the copies.

## Uninstall

- **Option A:** `/plugin uninstall spec-kit` (and optionally
  `/plugin marketplace remove spec-kit-marketplace`).
- **Option B:** delete the copied folders, e.g.
  `rm -rf ~/.claude/skills/spec-* ~/.claude/commands/{build,scan,rescan,review,ask,plan,map,document,help}.md ~/.claude/agents/{codebase-analyzer,impact-detector,business-flow-tracer,security-reviewer,architecture-reviewer,performance-reviewer,business-consistency-reviewer}.md`.

## Troubleshooting

| Symptom | Fix |
|---------|-----|
| `/plugin` is not recognized | Update Claude Code; plugins require a recent version. |
| `marketplace add` fails on a path | Pass an **absolute** path to `<PLUGIN_DIR>` and ensure `.claude-plugin/marketplace.json` exists there. |
| `git clone` asks for a password / permission denied | The repo is private — use an account with access, set up SSH keys, or have the owner share/publish it. |
| Commands don't show up | Reload the Claude Code window/session after install; for plain skills, confirm files landed in `.claude/commands` & `.claude/skills`. |
| A command says "no knowledge-base found" | Run `/spec-kit:scan` once in that repo (or reuse an existing `knowledge-base/` folder). |
| Command name clash (Option B) | Rename the files in `.claude/commands/`. |

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
