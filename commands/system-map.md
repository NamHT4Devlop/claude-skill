---
description: Map a microservices workspace end-to-end — cross-service dependency graph + business flows that span services (run at the workspace root)
argument-hint: "[optional: focus flow/service, e.g. checkout]"
---

Use the **namht-system-map** skill to build a SYSTEM-level map of the microservices in this
workspace folder: discover the service repos, stitch each one's exposed endpoints (KB
`11-api-docs`) to others' outbound calls (KB `14-integrations`) into a cross-service dependency
graph, trace **end-to-end business flows** that span services (sequence diagrams), and catalog
shared events/contracts + risks. Write to `<workspace>/system-map/` (dual-audience) and render
the graph + flows to HTML. Run this at the **workspace root** (parent of the service repos);
each service should ideally have a KB already (`/namht-scan`).

Optional focus (a specific flow or service to center on): $ARGUMENTS
