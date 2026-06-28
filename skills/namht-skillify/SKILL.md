---
name: namht-skillify
description: >-
  Scaffold a NEW namht-* skill (and its command) from a description, following
  this toolkit's conventions, so the user can self-extend the kit. Use when the
  user says "/skillify", "create a new skill", "add a skill for X", "turn this
  workflow into a skill", "make a command for …".
---

# namht-skillify — create a new skill the right way

Meta-skill: scaffold a new `namht-*` skill + command that matches this repo's standard, then wire
and document it. Operate inside the `claude-skill` repo (the toolkit source, e.g. `~/claude-skill`).

## Steps
1. **Clarify** the new skill: name (kebab, will become `namht-<name>`), one-line purpose, when it
   should trigger, inputs, output, whether it needs the HTML renderer or the review checklist.
2. **Create `skills/namht-<name>/SKILL.md`** with frontmatter:
   - `name: namht-<name>` (MUST equal the folder name), `description: >-` a 1–3 sentence trigger
     description (when to use + key verbs/aliases). Body = the methodology, grounded in CodeGraph/KB
     where relevant, with a clear Output section and Rules. Reuse the house style: CodeGraph-first,
     dual-audience output, change-discipline if it edits code.
3. **Create `commands/<name>.md`** (UNPREFIXED filename) — thin entry: frontmatter `description` +
   `argument-hint`, body "Use the **namht-<name>** skill to … $ARGUMENTS".
4. **If it needs bundles** (HTML render / review checklist): add `namht-<name>` to the right list in
   `scripts/sync-bundles.sh` (`map_html` for the renderer, `map_review` for the checklist), then run
   `bash scripts/sync-bundles.sh`.
5. **Install + docs:** run `bash scripts/personal-install.sh`; add a row to `commands/help.md`,
   the README command table, and `docs/*.html`; bump notes if needed.
6. **Verify:** `bash tests/run.sh` (skill-name==folder + sync check must pass).

## Rules
- Follow the established conventions exactly (naming, unprefixed command files, frontmatter shape,
  references via sync) so audit/tests stay green — don't invent a new structure.
- Keep the new skill focused (one job) and the description trigger-friendly.
- Don't duplicate an existing skill — check `commands/` first; extend instead if overlap.
- Commit message must NOT contain the literal phrase a git command would match (e.g. "git push") on
  one line — it trips the git-guard. Commit and push as separate commands.
