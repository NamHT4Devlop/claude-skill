---
description: Query Splunk for per-app errors over a window (default today), aggregate into a table, and post to Slack
argument-hint: "[apps + window, e.g. 'payments,orders today' | empty = ask]"
---

Use the **namht-splunk-report** skill to query Splunk for errors/exceptions per app, aggregate them
into a single table (app · total · top error · severity), and post it to Slack. Default time window
= today. Read-only on Splunk; prefer a connected Splunk/Slack MCP, else `curl` with credentials from
the environment (never hardcode); confirm the channel before posting.

Apps / time window / Slack channel:
$ARGUMENTS
