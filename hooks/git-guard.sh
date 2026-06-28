#!/usr/bin/env bash
# git-guard.sh — Claude Code PreToolUse hook (Bash).
# HARD-blocks git commands that affect the REMOTE or destroy local work.
# ALLOWS read / sync-in git: fetch, pull, status, log, diff, show, blame, branch (list),
# add, commit, stash, merge, checkout <branch>, etc.
#
# Decision is returned as PreToolUse JSON (permissionDecision: deny). Allowed → silent exit 0.
# Works on chained commands (cd x && git push), git -C, and ignores 'push' inside quotes/flags.

input=$(cat)
cmd=$(printf '%s' "$input" | jq -r '.tool_input.command // empty' 2>/dev/null)
[ -z "$cmd" ] && exit 0

# Fast path: only police strings that actually invoke git.
printf '%s' "$cmd" | grep -qE '(^|[^[:alnum:]_])git([[:space:]]|$)' || exit 0

deny() {
  local msg="🚫 namht git-guard chặn lệnh này: $1
Chỉ cho phép git ĐỌC/ĐỒNG BỘ (không đổi remote, không mất việc): fetch · pull · status · log · diff · show · blame · branch(list) · add · commit · stash · merge · checkout <branch>.
Nếu thật sự cần, người dùng tự chạy trong terminal."
  printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":%s}}\n' \
    "$(printf '%s' "$msg" | jq -Rs .)"
  exit 0
}

# Helper: does the command contain `git ... <subcmd>` within a single segment (not across ; && |),
# and not inside a quoted string? `[^"'\''|;&]*` stops at a quote or a command separator.
g() { printf '%s' "$cmd" | grep -qE "(^|[^[:alnum:]_])git\b[^\"'|;&]*[[:space:]]$1"; }

# ── REMOTE-affecting → ABSOLUTELY forbidden ───────────────────────────────────
g 'push([[:space:]]|$)'                                              && deny "git push (ghi lên remote)"
g 'remote[[:space:]]+(add|remove|rm|rename|set-url|set-head|set-branches|prune)\b' && deny "git remote thay đổi cấu hình remote"
g 'send-email\b'                                                     && deny "git send-email"
g 'svn[[:space:]]+dcommit\b'                                         && deny "git svn dcommit"
g 'p4[[:space:]]+submit\b'                                           && deny "git p4 submit"
g 'config[[:space:]]+[^"'"'"']*remote\.'                             && deny "sửa git config remote.*"

# ── Destructive LOCAL (mất việc / viết lại lịch sử) → forbidden ────────────────
g 'reset[[:space:]]+[^"'"'"']*--hard\b'                              && deny "git reset --hard (mất thay đổi)"
g 'clean[[:space:]]+-[A-Za-z]*f'                                     && deny "git clean -f (xoá file chưa track)"
g 'checkout[[:space:]]+(\.|--|-f|--force)([[:space:]]|$)'                            && deny "git checkout làm mất thay đổi"
g 'checkout[[:space:]]+[^"'"'"']*[[:space:]](\.|--|-f|--force)([[:space:]]|$)'        && deny "git checkout làm mất thay đổi"
g 'restore([[:space:]]|$)'                                           && deny "git restore (mất thay đổi)"
printf '%s' "$cmd" | grep -qE "(^|[^[:alnum:]_])git\b[^\"'|;&]*[[:space:]]branch[[:space:]]+[^\"'|;&]*(-D|--delete[[:space:]]+--force)\b" && deny "git branch -D (xoá nhánh, mất commit)"
g 'commit[[:space:]]+[^"'"'"']*--amend\b'                            && deny "git commit --amend (viết lại lịch sử)"
g 'rebase([[:space:]]|$)'                                            && deny "git rebase (viết lại lịch sử)"
g 'filter-(branch|repo)\b'                                           && deny "git filter-branch/filter-repo"
g 'reflog[[:space:]]+expire\b'                                       && deny "git reflog expire"
g 'gc[[:space:]]+[^"'"'"']*--prune'                                  && deny "git gc --prune"
g 'update-ref[[:space:]]+[^"'"'"']*-d\b'                             && deny "git update-ref -d"

exit 0  # everything else → allowed
