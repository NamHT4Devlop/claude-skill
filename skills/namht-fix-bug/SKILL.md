---
name: namht-fix-bug
description: >-
  Diagnose and fix a production bug from a symptom (error message, stack trace,
  failing endpoint, incident report): gather context, reproduce, find the ROOT
  CAUSE (not the symptom), assess blast radius, write a failing regression test,
  apply a minimal surgical fix, verify (tests + build) with rollback, and produce
  a hotfix report. Use when the user says "fix bug", "production bug", "hotfix",
  "/fix-bug", "this is erroring", "incident", or pastes an error/stack trace.
---

# namht-fix-bug — production bug → root cause → surgical fix → regression test

A focused hotfix pipeline, distinct from `/namht-build` (which builds features). Production = high
stakes, so the bias is: **understand deeply, change minimally, prove it with a test, don't break
anything else.** Ground in the code (structure/blast radius) + `knowledge-base/` (business rules).

## Ground rules
- **Root cause, not band-aid.** Fix *why* it breaks, not just the visible symptom. State the root
  cause explicitly before touching code.
- **Minimal, surgical, reversible.** Smallest diff that fixes the root cause; respect the
  "Architecture Invariants — DO NOT BREAK" and conventions; no drive-by refactors (see the change
  discipline in `namht-build`). For risky fixes, prefer a guard/feature-flag and note a rollback.
- **Prove it with a test.** A regression test that FAILS before the fix and PASSES after.
- **Read the code path first.** From the stack trace, Read the failing files and **grep for callers**
  to pull the exact code path + blast radius before changing anything.
- **Never deploy/push.** Produce the fix + test locally; the human deploys. (The git-guard hook
  blocks remote pushes anyway.)

## Pipeline

### 1. Intake & triage
Capture the report: **symptom**, error message / **stack trace**, affected endpoint/feature/job,
environment, severity, when it started (recent deploy?), and any repro steps or sample input.
If key facts are missing (no error text, no repro, unclear scope), **ask 2–4 targeted questions**
before digging. Note severity/urgency.

### 2. Locate the code path
From the stack trace / symptom, find the exact failing code:
- Read the top stack-trace files and **grep the failing function** → its source + callers.
- Map the request/flow end-to-end (entry → service → data) using the KB `10-core-flows` / `modules/`.
Identify the precise function(s) and the line(s) implicated.

### 3. Reproduce
Reproduce the failure locally where feasible: run the failing test, hit the endpoint, or write a
tiny harness with the offending input. Confirm you see the same symptom. If you cannot reproduce,
say so and proceed on the strongest evidence (logs + code reading), flagging the uncertainty.

### 4. Root-cause analysis
Trace **why**: follow the data/state through the call path, inspect inputs, nulls, types, edge
cases, concurrency, error handling, assumptions. Distinguish the **root cause** (the real defect)
from the **symptom** (where it surfaced). Write a clear root-cause statement:
> *"Root cause: `X` in `file:func` does Y when Z, because …"* — with the evidence (cited lines).
Check the KB: did the bug violate a documented business rule, or expose an **under-enforced** one?

### 5. Blast radius
Before fixing, find what else is affected:
- **Grep the callers/impact** of the function you'll change → every consumer to re-verify.
- Does the **same defect pattern** exist elsewhere? (search siblings.) Note them (fix now if
  trivial + in scope, else list as follow-ups).
- Which business flows/rules must the fix preserve?

### 6. Plan the minimal fix
State the exact change: files + lines, the corrected logic, why it fixes the root cause, and why
it's safe (conforms to architecture, preserves behavior elsewhere). For non-trivial/risky fixes,
show the plan and get a quick OK. Include a **rollback note**.

### 7. Regression test FIRST (red)
Write a test that reproduces the bug and currently **fails** — this proves you understood it.
Name it for the bug (`should … when <the buggy condition>`). Cover the exact failing case + the
obvious neighbors (boundary/null/error path).

### 8. Apply the fix (minimal diff)
Implement the planned change with Edit — scope-locked, minimal, matching style. Make the
regression test pass. No unrelated edits.

### 9. Verify (with rollback)
Run, in order: the new regression test (now **green**), the related/affected test suite, and the
project's build/lint/typecheck. Confirm no regressions in the blast-radius consumers. **If it
can't be made green quickly, revert** and report what blocked you — never leave prod code broken.

### 10. Hotfix report (dual-audience) + KB
Save to `spec-kit-sessions/fixes/<slug>-<date>.md` (and offer an HTML via the render step if useful):
- **In plain words** (for incident comms / non-tech): what broke, impact, what we changed, status.
- **Root cause** (cited), **the fix** (diff summary), **regression test**, **test results**,
  **blast radius checked**, **risk + rollback plan**, **follow-ups** (other places to harden).
Then **update the KB**: if the bug revealed a missing/under-enforced rule, add it to
`13-business-rules.md` and **Section 14** of `review-skills.md` so a future `/namht-build` or
`/namht-review` catches it. Remind the user to deploy (you don't).

## Output
Summarize in chat: root cause (1–2 lines), the fix, test status, risk/rollback, follow-ups, and
the report path. Be honest if you couldn't reproduce or fully verify.
