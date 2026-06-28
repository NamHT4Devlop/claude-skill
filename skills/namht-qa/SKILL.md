---
name: namht-qa
description: >-
  Turn a user story (role/action/benefit + acceptance criteria) into a complete
  QA test plan: derive test cases for the NEW flow (happy/alternate/error/edge/
  negative/permission/state) AND regression cases for the EXISTING (old) business
  flows the change touches — grounded in the Knowledge Base + CodeGraph — with a
  traceability matrix (AC ↔ case ↔ flow), Gherkin + a manual test-case table.
  Use when QA receives a story and needs test cases, or the user says "/qa",
  "viết test case", "test plan", "QA cho story này", "cover old and new flow".
---

# namht-qa — user story → test cases covering OLD + NEW business flows

For QA: take a user story and produce a **test plan a tester can execute**, that deliberately
covers BOTH the new behavior AND the existing flows it could break (regression). Grounds the
"old flow" in the repo's Knowledge Base (`10-core-flows`, `13-business-rules`, `modules/<m>`) and
CodeGraph (real endpoints/handlers). This is **test design** — it does NOT write or run code
(hand to `/namht-build` for automation if needed).

## Inputs
- The **user story** (role / action / benefit) + its **acceptance criteria**. Accept it pasted,
  by ID, or from a `/namht-plan` output under `spec-kit-sessions/`. If ACs are missing or vague,
  derive a draft set and flag assumptions (don't silently guess).
- The **feature/module** it touches (infer from the story; confirm via KB/CodeGraph).
- If the repo has no `knowledge-base/`, say so — old-flow/regression coverage will be weaker;
  suggest `/namht-scan`. If `.codegraph/` exists, use `codegraph_explore` to find the exact
  endpoints/handlers/state machines involved.

## Procedure
1. **Understand the story.** Restate role/action/benefit + each AC. List the entities, endpoints,
   states, roles and rules involved.
2. **Map the blast radius — THIS drives regression coverage.** Identify the symbols/endpoints the
   story will change, then use BOTH tools (they answer different halves):
   - **CodeGraph = WHERE the impact is (authoritative).** `codegraph_explore` on those symbols and
     read its **"Blast radius"** section, or run `codegraph impact <symbol>` / `codegraph callers
     <symbol>` / `codegraph affected <changed-files>`. Every caller/consumer it lists is a
     **regression target** — including the **non-obvious** ones QA would never guess from the story
     alone (a shared helper/service used by other features). It also flags symbols with **no
     covering tests** = highest-risk regression cases.
   - **KB = WHAT business flow each impacted point belongs to.** Map those impacted
     symbols/endpoints to documented flows & rules (`10-core-flows`, `13-business-rules`,
     `modules/`) → the user-facing behavior each regression target protects.
   - **Result:** the **NEW flow** (from the story) + a concrete **regression set** =
     CodeGraph blast radius × KB flows/rules. No `.codegraph/` → fall back to KB + grep and say the
     impact analysis is weaker (likely misses non-obvious consumers).
3. **Design NEW-flow cases** — for the new behavior, cover every angle:
   happy path · alternate/secondary paths · error & exception · **boundary/edge** (min/max,
   empty, null, very large) · **negative/invalid input** · **permission/role** (allowed vs
   forbidden) · **state-machine transitions** (valid + invalid) · data variations ·
   concurrency/duplicate/idempotency where relevant.
4. **Design REGRESSION cases (old flow)** — one per regression target in step 2's blast radius
   (each impacted caller/consumer/flow, **including the non-obvious ones CodeGraph surfaced**).
   Write cases asserting the OLD behavior still holds after the change. Label `[REGRESSION]`, cite
   the KB rule/flow they protect (e.g. BR-V2, core-flow #3), and bump priority for targets CodeGraph
   flagged as having **no covering tests**.
5. **Non-functional (only if relevant)** — security (authz/IDOR, injection), input validation,
   rate/limits/performance, audit/logging.
6. **Traceability** — every AC maps to ≥1 case; every touched old flow has ≥1 regression case.
   Flag any AC with no case and any touched flow with no regression as a **coverage gap**.

## Output (dual-audience; save + render HTML)
Save to `spec-kit-sessions/qa/<story-slug>-<date>.md`, then render to HTML and open it
(`node "$HOME/.claude/skills/namht-qa/references/render-html.cjs" <md> <html> "<story>"`).
Structure:
```
# QA Test Plan — <story title>

## In plain words (cho non-tech: cover gì, vì sao đủ)
2–4 câu: tính năng test gì, đã bảo vệ flow cũ nào, tổng số case + mức rủi ro.

## Story & scope
role/action/benefit · acceptance criteria · modules/endpoints touched · old flows at risk.

## Traceability matrix
| AC / Flow | Test case IDs | Type (new/regression) | Covered? |

## Test cases (Gherkin)
### TC-01 — <title>   [NEW · happy · P1]
Given … When … Then …
### TC-07 — <title>   [REGRESSION · protects BR-V2 / core-flow #3 · P1]
Given (existing precondition) … When … Then (old behavior unchanged) …

## Test cases (manual table)
| ID | Title | Type | Priority | Preconditions | Steps | Expected | Test data |

## Test data & environment
fixtures/users/roles needed; env notes.

## Coverage gaps & risks
ACs without a case, old flows without regression, ambiguities to confirm with PO/dev.
```

## Rules
- **Always include regression for the old flow** — this is the point; never produce only
  new-flow cases. If the change touches an existing flow and you wrote no regression case, that's
  a gap to call out.
- Cases must be **concrete and executable** (real fields/endpoints/values from KB/CodeGraph),
  not vague ("test the API"). Each case has a clear expected result.
- Prioritize (P1/P2/P3) and tag type ([NEW]/[REGRESSION]/[NEGATIVE]/[EDGE]/[SECURITY]).
- It's a plan for testers — don't edit app code. Offer to scaffold automated tests via
  `/namht-build` if the user wants them coded.
