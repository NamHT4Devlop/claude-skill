---
description: Install / wire / manage CodeGraph — the agent-queryable code graph (MCP). Subcmds: setup|install|init|status|update|uninstall
argument-hint: "[setup|install|init|status|update|uninstall|help] (default: setup)"
---

Use the **namht-codegraph** skill to manage CodeGraph (the local, agent-queryable code
knowledge graph that wires into Claude Code over MCP). Route on the subcommand below; default
to the smart end-to-end `setup` (install CLI → wire MCP → init this repo). Confirm before any
step that installs software or modifies MCP config. After wiring, remind me to reload Claude
Code. This is the agent-facing graph — distinct from `/namht-map` (human visual).

Subcommand: $ARGUMENTS
