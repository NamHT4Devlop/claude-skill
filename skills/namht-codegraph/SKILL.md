---
name: namht-codegraph
description: >-
  Install, wire up, and manage CodeGraph (github.com/colbymchenry/codegraph) — a
  100% local, pre-indexed code knowledge graph that an AI agent queries over MCP
  (symbols, call edges, dependencies, blast radius) for fewer tool calls and
  tokens. Use when the user asks to "/namht-codegraph", "set up CodeGraph",
  "index this repo for the agent", "plug in codegraph", or wants an
  agent-queryable code graph (different from /namht-map, which is a human visual).
---

# namht-codegraph — manage CodeGraph (agent-queryable code graph via MCP)

This wraps the real **CodeGraph** tool. Unlike `namht-map` (an interactive HTML graph for
*humans*), CodeGraph builds a local index that the *AI agent* queries through an **MCP server** —
so Claude can ask for the exact symbols/call-paths/blast-radius instead of grepping files.

> CodeGraph is a separate program (npm `@colbymchenry/codegraph`, MIT, 100% local). The power
> comes from its **MCP server**, which `codegraph install` wires into Claude Code — this skill
> just drives its CLI. After wiring, **reload Claude Code** so the MCP tools appear; then you
> don't call a command — you just ask normally and Claude uses the CodeGraph MCP tools.

## Subcommand routing
Read the argument (`$ARGUMENTS` from the command, or infer from the user). Run the matching
step with `Bash`. **`codegraph install` and `init` modify the agent's MCP config and write a
local index — confirm with the user before running if it wasn't explicitly requested.**

- **(no arg) / `setup` / `bootstrap`** — smart end-to-end:
  1. If `command -v codegraph` fails → install the CLI (see below).
  2. Run `codegraph install` to wire the MCP server into Claude Code (user-level).
  3. If the current repo has no `.codegraph/` → `codegraph init` (builds the graph; auto-sync
     keeps it fresh afterward).
  4. Tell the user to **reload Claude Code**, then just ask questions normally.
- **`install`** — only install the CLI + `codegraph install` (wire MCP), no project init.
- **`init`** — `cd` to the project and run `codegraph init` (build this repo's graph).
- **`status`** — `command -v codegraph`, `codegraph --version`, check `.codegraph/` exists; if a
  status/list subcommand exists (`codegraph --help`), show it.
- **`update` / `upgrade`** — `codegraph upgrade` (add `--check` to just check).
- **`uninstall`** — `codegraph uninstall` (removes its MCP config from agents). To drop a repo's
  index: `codegraph uninit` in that repo.
- **`help`** — run `codegraph --help` and summarize.

If unsure which subcommands/flags exist, run `codegraph --help` first and follow it — don't
invent flags.

## Installing the CLI (no Node required — bundles its own runtime)
- macOS / Linux:
  ```bash
  curl -fsSL https://raw.githubusercontent.com/colbymchenry/codegraph/main/install.sh | sh
  ```
- Windows (PowerShell):
  ```powershell
  irm https://raw.githubusercontent.com/colbymchenry/codegraph/main/install.ps1 | iex
  ```
- Already have Node: `npm i -g @colbymchenry/codegraph`

The installer puts `codegraph` on PATH but doesn't change the current shell — open a new
terminal (or `hash -r`) so the command resolves before the next step.

## Personal / zero-footprint notes
- `.codegraph/` (the per-repo index) is already in the user's **global gitignore**, so it never
  gets committed to a team repo.
- Prefer wiring the MCP server at **user scope** (the default for `codegraph install`) so no
  project `.mcp.json` is added to a shared repo. If asked to add it per-project, warn that this
  writes a file teammates would see.
- Everything is 100% local; no code leaves the machine.

## Relationship to the rest of the kit
- `namht-map` = visual graph for *you* (browser). `namht-codegraph` = queryable graph for the
  *agent* (MCP). They're complementary — use map to understand, CodeGraph to make Claude faster.
- CodeGraph indexes code structure; it does NOT replace the `knowledge-base/` (business intent,
  rules, flows) that `namht-scan`/`namht-build` rely on.
