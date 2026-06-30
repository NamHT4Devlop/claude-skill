---
name: namht-splunk-report
description: >-
  Query Splunk for errors/exceptions per app over a time window (default: today),
  aggregate the findings into one table (app · total · top error · severity), and
  post it to a Slack channel. Use when the user says "/splunk-report", "splunk
  error report", "daily error digest", "query splunk errors and send to slack",
  or wants a per-app error summary from Splunk for the day.
---

# namht-splunk-report — per-app Splunk error digest → Slack

Pull error/exception counts from Splunk for each app, roll them up into one table, and post it to
Slack. **Read-only** on Splunk; **never** stores or prints credentials. (This skill needs network +
Splunk/Slack access — unlike the rest of the kit, which is local-only.)

## Inputs — ASK the user for these (they form the query filter)
The base Splunk filter is **`index={A} cai_enviroment={B} cai_app={C}`**. Ask the user for each
variable; **if a variable is NOT provided, OMIT that clause entirely** (do not guess a value):
- **A = `index`** — the Splunk index.
- **B = `cai_enviroment`** — the environment (e.g. prod/staging). *(Field name kept verbatim as it
  is in the user's Splunk schema — do not "correct" the spelling.)*
- **C = `cai_app`** — the app. Accept a **list** of apps → one row per app in the table. If `C` is
  omitted, query without `cai_app` and break it down in `stats` (`by cai_app`) so the table still
  has per-app rows.
- **Time window** — default **today** (`earliest=@d latest=now`). Accept "last 24h" (`-24h@h`) or an explicit range.
- **Slack channel** — the target channel (or user). Confirm before posting.

## Access — use whatever is available, in this order
**Splunk (read-only search):**
1. A connected **Splunk MCP** (`mcp__*splunk*…`) — preferred.
2. **REST API via `curl`** (credentials from the environment, NEVER hardcoded):
   ```bash
   curl -s -H "Authorization: Bearer $SPLUNK_TOKEN" \
     "$SPLUNK_HOST/services/search/jobs/export" \
     --data-urlencode 'search=search index={A} cai_enviroment={B} cai_app={C} (error OR Exception OR FATAL OR log_level=ERROR) earliest=@d latest=now | stats count AS total by error_type, log_level | sort -total' \
     --data-urlencode output_mode=json
   ```
   Substitute `{A}`/`{B}`/`{C}` with the values the user gave, and **drop any of `index=` /
   `cai_enviroment=` / `cai_app=` whose variable was not provided**. Adapt `error_type`/`log_level`
   to the project's schema.
3. **Splunk CLI** — `splunk search '<spl>'` if installed.
4. None available/authed → ask the user to connect Splunk or paste the search results; don't guess.

**Slack (post the report):**
1. A connected **Slack MCP** (`mcp__*slack*…send_message`) — preferred.
2. **Incoming webhook** — `curl -X POST -H 'Content-type: application/json' --data '{"text":"…"}' "$SLACK_WEBHOOK_URL"`.
3. None → save the report and give the user the text to paste; offer to connect Slack.

## Procedure
1. **Ask for `index` (A), `cai_enviroment` (B), `cai_app` (C)**, the time window, and the Slack
   channel. Build the base filter `index={A} cai_enviroment={B} cai_app={C}`, **dropping any clause
   whose variable the user did not provide**. Confirm the channel.
2. **Run the error search per app** (read-only) — loop once per `cai_app` value the user gave (or,
   if `C` was omitted, run one search with `… | stats count by cai_app, error_type`). Capture:
   total errors, the top N error types/messages with counts, and a breakdown by severity/level.
   Record the exact SPL + time range.
3. **Aggregate into one table** across all apps, sorted by total desc, with a TOTAL row:
   `| App | Total | Top error | Count | Severity | Notable |`.
   Flag spikes / new error types vs. a prior run if that context is available.
4. **Format for Slack** — a monospace code-block table (```), or Block Kit fields. Keep it compact;
   put the time window + a timestamp in the header.
5. **Confirm, then post** to the Slack channel. Sending is an **outward action** — show the message
   and get an OK first, unless the user explicitly said to auto-send.
6. **Save** a copy to `spec-kit-sessions/splunk/<date>.md` (gitignored).

## Output (Slack message shape)
```
:rotating_light: Error digest — <date> (today, <tz>)
App         | Errors | Top error              | Count
------------|--------|------------------------|------
payments    |    142 | NullPointerException   |    61
orders      |     38 | TimeoutException       |    20
notifier    |      9 | SqsConsumeError        |     6
------------|--------|------------------------|------
TOTAL       |    189 |                        |
```
Add 1–2 lines: biggest mover / anything that needs attention.

## Daily run
This skill produces **one** report on demand. To run it **every day**, schedule the trigger
externally — a cron job that invokes Claude Code with `/namht-splunk-report`, or a scheduled
Claude routine. The skill itself is unchanged; only the schedule lives outside it.

## Rules
- **Read-only on Splunk** — search only; never write, delete, or modify.
- **Never hardcode, print, log, or commit credentials** (`$SPLUNK_TOKEN`, `$SLACK_WEBHOOK_URL`,
  cookies). Read them from the environment or the connected MCP. If missing, ask the user to set them.
- **Confirm before posting to Slack** (outward action) unless the user explicitly authorized auto-send.
- **Report only real results** — cite the exact SPL + time range; if a query failed or returned
  nothing for an app, say so for that app rather than inventing counts.
- Group/normalize errors sensibly (by exception class or message signature) so the table is useful,
  not a wall of unique strings.
