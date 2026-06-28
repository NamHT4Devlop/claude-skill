---
name: namht-system-map
description: >-
  Build a SYSTEM-LEVEL map across multiple microservice repos in one workspace
  folder: discover the services, stitch each service's exposed endpoints (KB
  11-api-docs) to the others' outbound calls (KB 14-integrations) into a
  cross-service dependency graph, trace END-TO-END business flows that span
  services (with sequence diagrams), and catalog shared events/contracts + risks.
  Use when the user asks to "/system-map", "map the microservices", "end-to-end
  flow across services", "how do the services call each other", or works in a
  folder containing several service repos that call each other.
---

# namht-system-map — cross-service / end-to-end map for a microservices workspace

Per-service `/namht-scan` + CodeGraph understand each service **internally**. This skill adds the
**second layer**: how the services connect (HTTP/gRPC/queues/events) and the **end-to-end business
flows** that span them. It works for a **multi-repo workspace** — a parent folder containing N
service repos in possibly different languages.

## Inputs & setup
- **Run at the workspace root** (the parent folder that contains the service repos).
- **Discover services:** each immediate sub-folder that is a git repo or has a manifest
  (`package.json`, `pom.xml`/`build.gradle`, `go.mod`, `Gemfile`, `requirements.txt`,
  `*.csproj`, `Cargo.toml`) and/or a `knowledge-base/`. List them with detected language + role.
- **Precondition (strongly recommended):** each service should already have a Knowledge Base
  (`cd <svc> && /namht-scan`). If some don't, list them and offer to scan them first — the system
  map is far more accurate from per-service KBs. You can still proceed using CodeGraph + source for
  un-scanned services, at lower fidelity (say so).
- **CodeGraph across services:** if a service has `.codegraph/`, use `codegraph_explore` with
  `projectPath: <svc>` to confirm the real HTTP-client calls / endpoint handlers / queue
  producers-consumers when the KB is thin. You can query many services in one session.

## What to build
For each service, read its KB: `11-api-docs.md` (endpoints it **exposes**), `14-integrations.md`
(systems/services/queues it **calls out to**), `03-entry-points.md`, `06-modules.md`, plus
`10-core-flows.md` (its internal flows). Then:

1. **Service inventory** — name, language/stack, role, base URL/route prefix, exposed surface.
2. **Cross-service dependency graph** — match each service's **outbound** targets (base URLs,
   service names, gRPC services, Kafka/SQS topics, event names) to the **inbound** side of other
   services (their endpoints / consumers). Edge = caller → callee, labelled with protocol
   (REST/gRPC/queue/event) and the operation. Flag edges you inferred vs. confirmed in code.
3. **End-to-end business flows (3–7 key ones)** — trace a user/system action from its **entry
   service** through every downstream hop to completion. For each: a Mermaid `sequenceDiagram`
   (participant per service), the trigger, each hop (service · endpoint/handler · protocol),
   state changes, and failure/compensation paths. Cite the file/endpoint in each service.
4. **Shared contracts & events** — catalog cross-service contracts: REST request/response shapes
   at boundaries, gRPC protos, **event/topic schemas** (producer ↔ consumers). Note ownership.
5. **Risks** — synchronous chains (latency/cascade failure), missing idempotency on consumers,
   contract/version skew between services, single points of failure, chatty calls, no
   circuit-breaker/timeout, auth between services.

## Output (write to `<workspace>/system-map/`)
Dual-audience (plain summary + technical detail), each file Markdown:
- `_index.md` — links + last-updated + service list.
- `00-system-overview.md` — **In plain words** (what the system does, who the services are) +
  the inventory table.
- `01-service-dependency-graph.md` — a Mermaid `flowchart` (nodes = services, edges = calls,
  grouped by layer: edge/gateway → core → data/async); written analysis of hubs, cycles,
  sync-coupling hot-spots.
- `02-end-to-end-flows.md` — the cross-service flows with sequence diagrams.
- `03-contracts-events.md` — contracts/events tables + risks.

Then **render `01` and `02` to HTML** (diagrams drawn) with the bundled renderer and open them:
```bash
node "$HOME/.claude/skills/namht-system-map/references/render-html.cjs" \
  "<workspace>/system-map/02-end-to-end-flows.md" "<workspace>/system-map/02-end-to-end-flows.html" "End-to-end flows"
# then: open / xdg-open / start  the printed path
```

## Notes
- `system-map/` is a workspace-level artifact (the parent folder usually isn't a git repo). It's
  also covered by the global gitignore (`system-map/`) so it never lands in a service repo.
- **Keep it fresh:** after a service changes its API/integrations, `/namht-rescan` that service,
  then re-run `/namht-system-map` (or just re-derive the affected flow).
- Polyglot is fine — the map works off **contracts/events** (language-agnostic), not code imports;
  each service's own KB/CodeGraph handled its language.
- This is a *map*, not a deploy/runtime tool — it documents the system from code+KB; confirm
  uncertain edges with the team or by reading the actual client/handler via CodeGraph.
