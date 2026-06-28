---
name: namht-retro
description: >-
  Run an engineering retrospective over a time window from git history (read-only):
  what shipped, recurring themes/pain, what went well vs poorly, risk/quality
  signals, and concrete action items for next period. Use when the user says
  "/retro", "weekly retro", "what did we ship", "retrospective", "sprint review".
---

# namht-retro — engineering retrospective from git history

(Adapted from gstack's "retro" idea, MIT.) A periodic look-back grounded in real history.

## Gather (read-only git + artifacts)
- Window: default last 7 days (or what the user names). `git log --since=<window> --stat`,
  `git shortlog -sn --since`, `git diff --stat <since>..HEAD` for churn by area.
- Optional signals: `spec-kit-sessions/` reports (fixes/reviews/qa) from the window; open TODO/FIXME
  added; CodeGraph "no covering tests" on changed areas (test-debt trend).

## Produce (dual-audience; chat + save `spec-kit-sessions/retro/<date>.md`)
```
## In plain words            ← the period in 3 bullets (shipped / notable / watch-outs)
## Shipped                   ← features/fixes merged (grouped by area), with size
## What went well            ← concrete wins (cite commits/PRs)
## What hurt                 ← recurring pain: churned files, repeated bug areas, review themes
## Quality & risk signals    ← test-debt (no-covering-tests), hotspots (high churn), regressions seen
## Action items              ← 3–6 concrete, owned, doable next-period actions
```

## Rules
- Ground every claim in git/artifacts (cite commits/files). No vague "team did great".
- Read-only — never mutate git. Keep it honest: surface the pain, not just wins.
- Tie action items to the toolkit where useful (e.g. "run /namht-qa on module X — it has no tests").
