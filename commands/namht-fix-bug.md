---
description: Fix a production bug — gather context, find ROOT CAUSE, write a failing regression test, apply a minimal surgical fix, verify
argument-hint: <error message / stack trace / bug description>
---

Use the **namht-fix-bug** skill to diagnose and fix the production bug below: triage → locate the
code path (CodeGraph-first) → reproduce → **root-cause analysis** (not just the symptom) → blast
radius → minimal surgical fix with a **failing-then-passing regression test** → verify (tests +
build, rollback if broken) → hotfix report + KB update. Do NOT deploy/push — the human deploys.

Bug (paste the error / stack trace / symptom; include env, repro, severity if known):
$ARGUMENTS

If the report lacks an error/stack trace or repro, ask 2–4 targeted questions before digging in.
