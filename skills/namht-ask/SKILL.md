---
name: namht-ask
description: >-
  Answer natural-language questions about a codebase grounded ONLY in its
  Knowledge Base (knowledge-base/ + modules/), for a mixed business+technical
  audience: a plain-language explanation, a fitting Mermaid diagram, and the
  precise technical detail with real file/field/endpoint citations. Use when the
  user asks "/ask", "how does X work", "which module handles Y", "where is Z
  implemented", or any Q&A about the project.
---

# Spec Ask — grounded codebase Q&A

A native port of Auto Spec Kit's `/ask`. Answer using **only** the project's Knowledge Base;
never invent files, APIs, fields, or behavior.

## Procedure
0. **Prefer CodeGraph for code grounding.** If the repo has a `.codegraph/` index and the
   question is about *how code works / where something is*, call the `codegraph_explore` MCP
   tool (verbatim source + call paths in one shot) to ground the **Technical detail** section —
   far cheaper than Grep/Read. The KB still supplies business meaning. Pass `projectPath` if needed.
1. **Select relevant KB context.** Map the question to topics and load just those
   `knowledge-base/` docs (don't dump the whole KB). If the question names a module/feature,
   load the matching `knowledge-base/modules/<module>.md` first — those deep docs are the
   richest context. Fall back to reading the actual source only if the KB lacks the answer
   (and say so).
2. **Detect vagueness.** If the question is broad/under-specified, first state your
   interpretation + assumptions, answer the most likely intent, then ask 2–3 clarifying
   questions.

## Answer structure (always, in this order) — dual audience
Write so a **non-technical reader (founder / PM / ops) AND an engineer both get full value from
the same answer.** Layer it plain → precise: never assume tech background in the top sections,
never lose precision at the bottom, and define every unavoidable term.
```
## TL;DR (one line — for everyone)
One jargon-free sentence that answers the question. Add a short analogy if it helps.

## In plain language (business / non-tech)
What it is, why it matters, how it behaves — everyday business terms. NO unexplained jargon:
the first time a technical word is unavoidable, define it inline in parentheses. A non-technical
reader must fully understand this section on its own.

## Diagram
A Mermaid diagram that fits the question — flowchart for a flow, erDiagram for data/fields,
sequenceDiagram for an interaction. Use a valid ```mermaid block, short plain labels. If a
diagram truly doesn't apply, write "(no diagram needed)".

## Technical detail (engineers)
The precise answer, citing concrete names from the KB / CodeGraph: files, modules, endpoints,
entities, fields, functions. Full accuracy here — don't dumb it down.

## In plain words (glossary)
Any technical term used above → a one-line everyday definition. Omit the section if there were none.
```

## Rules
- **Same facts, two depths.** The plain sections and the technical section must not contradict —
  one is a simpler view of the other, not a different answer.
- Ground every claim in the KB. If it doesn't contain the answer, say so explicitly.
- When mapping business ↔ code, name the exact field / file / function.
- If `knowledge-base/` is missing entirely, tell the user to run `/namht-scan` first;
  you can still answer from direct code reading but flag the lower confidence.

## Output — answer in chat, THEN save an HTML file
1. **Answer in chat first** using the full dual-audience structure above (this is the primary output).
2. **Save the same content** to `spec-kit-sessions/answers/<slug>-<date>.md` (slug from the question).
3. **Render a self-contained HTML** (styled, with the Mermaid diagram drawn) using the bundled renderer:
   ```bash
   node "$HOME/.claude/skills/namht-ask/references/render-html.cjs" \
     "<repo>/spec-kit-sessions/answers/<slug>-<date>.md" \
     "<repo>/spec-kit-sessions/answers/<slug>-<date>.html" "<question>"
   ```
   (It prints the HTML path. Requires Node — if absent, keep the chat + `.md` and say HTML was skipped.)
4. **Open it**: macOS `open "<path>"` · Linux `xdg-open` · Windows `start "" "<path>"`. Give the user the path.

Output lands under `spec-kit-sessions/` (gitignored) — no footprint in the repo.
