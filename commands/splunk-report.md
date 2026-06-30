---
description: Query Splunk for per-app errors over a window (default today), aggregate into a table, and post to Slack
argument-hint: "[index=A cai_enviroment=B cai_app=C + window | empty = the skill asks]"
---

Use the **namht-splunk-report** skill to query Splunk for errors/exceptions, aggregate them into a
single table (app · total · top error · severity), and post it to Slack. The query filter is
`index={A} cai_enviroment={B} cai_app={C}` — the skill **asks for A/B/C** and **skips any variable
you don't pass**. Default time window = today. Read-only on Splunk; prefer a connected Splunk/Slack
MCP, else `curl` with credentials from the environment (never hardcode); confirm the channel before posting.

index (A) / cai_enviroment (B) / cai_app (C) / time window / Slack channel:
$ARGUMENTS
