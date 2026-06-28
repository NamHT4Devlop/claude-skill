---
description: Scaffold a NEW namht-* skill + command from a description, following this toolkit's conventions, then wire and document it
argument-hint: <new skill name + what it should do>
---

Use the **namht-skillify** skill to scaffold a new `namht-*` skill from the description below:
create `skills/namht-<name>/SKILL.md` (name == folder) + `commands/<name>.md` (unprefixed), add it
to `scripts/sync-bundles.sh` if it needs the renderer/checklist, run sync + `personal-install.sh`,
add a row to help/README/docs, and verify with `tests/run.sh`. Follow the house conventions exactly.

New skill (name + purpose):
$ARGUMENTS
