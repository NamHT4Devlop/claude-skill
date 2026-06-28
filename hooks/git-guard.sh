#!/usr/bin/env bash
# git-guard.sh — Claude Code PreToolUse hook (Bash).
#
# Policy:
#   • git push          → ALLOWED only to a WHITELISTED personal remote (see ALLOW_OWNER_RE);
#                         pushes to any other remote (team/org repos) are BLOCKED.
#   • other remote ops  → BLOCKED (remote add/set-url/…, send-email, svn dcommit, p4 submit, config remote.*)
#   • destructive local → BLOCKED (reset --hard, clean -f, checkout --/./-f, restore, branch -D,
#                         commit --amend, rebase, filter-branch, reflog expire, gc --prune, update-ref -d)
#   • everything else   → ALLOWED (fetch, pull, status, log, diff, show, blame, add, commit, stash,
#                         merge, checkout <branch>, …)
#
# Robust: handles chained commands (cd x && git push), git -C, and ignores the word inside quotes.

# ── EDIT ME: personal namespaces allowed to receive pushes ────────────────────
ALLOW_OWNER_RE='github\.com[:/](NamHT4Devlop)/'   # add more: (NamHT4Devlop|my-other-user)

input=$(cat)
cmd=$(printf '%s' "$input" | jq -r '.tool_input.command // empty' 2>/dev/null)
[ -z "$cmd" ] && exit 0
printf '%s' "$cmd" | grep -qE '(^|[^[:alnum:]_])git([[:space:]]|$)' || exit 0

deny() {
  local msg="🚫 namht git-guard chặn lệnh này: $1
Cho phép: git ĐỌC/ĐỒNG BỘ (fetch·pull·status·log·diff·show·blame·add·commit·stash·merge·checkout <branch>) và PUSH tới repo cá nhân được whitelist. Cấm: push repo khác + thao tác phá huỷ. Cần làm khác → tự chạy trong terminal."
  printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":%s}}\n' \
    "$(printf '%s' "$msg" | jq -Rs .)"
  exit 0
}

# git ... <subcmd> within one segment (not across ; && |), not inside quotes.
g() { printf '%s' "$cmd" | grep -qE "(^|[^[:alnum:]_])git\b[^\"'|;&]*[[:space:]]$1"; }

# ── PUSH → whitelist by target remote owner ───────────────────────────────────
if g 'push([[:space:]]|$)'; then
  url=$(printf '%s' "$cmd" | grep -oE '(https://[^ ]+|ssh://[^ ]+|git@[^ ]+)' | head -1)
  if [ -z "$url" ]; then
    # resolve working dir: `git -C <dir>`, else leading `cd <dir>`, else hook cwd, else $PWD
    dir=$(printf '%s' "$cmd" | sed -nE 's/.*-C[[:space:]]+([^ ]+).*/\1/p' | head -1)
    [ -z "$dir" ] && dir=$(printf '%s' "$cmd" | sed -nE 's/.*(^|[;&|[:space:]])cd[[:space:]]+([^ &;|]+).*/\2/p' | head -1)
    [ -z "$dir" ] && dir=$(printf '%s' "$input" | jq -r '.cwd // empty' 2>/dev/null)
    [ -z "$dir" ] && dir="$PWD"
    dir="${dir/#\~/$HOME}"
    # remote name = first non-option token after 'push' (default origin)
    rest=$(printf '%s' "$cmd" | sed -nE 's/.*[[:space:]]push//p')
    remote=""
    for tok in $rest; do
      case "$tok" in -*|*://*|git@*) continue;; *) remote="$tok"; break;; esac
    done
    [ -z "$remote" ] && remote=origin
    url=$(git -C "$dir" remote get-url "$remote" 2>/dev/null)
  fi
  if printf '%s' "$url" | grep -qE "$ALLOW_OWNER_RE"; then
    exit 0   # whitelisted personal remote → allow
  fi
  deny "git push tới remote KHÔNG thuộc whitelist cá nhân (${url:-không xác định được remote}) — chỉ cho push NamHT4Devlop/*"
fi

# ── other REMOTE-affecting → forbidden ────────────────────────────────────────
g 'remote[[:space:]]+(add|remove|rm|rename|set-url|set-head|set-branches|prune)\b' && deny "git remote thay đổi cấu hình remote"
g 'send-email\b'                                && deny "git send-email"
g 'svn[[:space:]]+dcommit\b'                    && deny "git svn dcommit"
g 'p4[[:space:]]+submit\b'                      && deny "git p4 submit"
g 'config[[:space:]]+[^"'"'"']*remote\.'        && deny "sửa git config remote.*"

# ── destructive LOCAL → forbidden ─────────────────────────────────────────────
g 'reset[[:space:]]+[^"'"'"']*--hard\b'         && deny "git reset --hard (mất thay đổi)"
g 'clean[[:space:]]+-[A-Za-z]*f'                && deny "git clean -f (xoá file chưa track)"
g 'checkout[[:space:]]+(\.|--|-f|--force)([[:space:]]|$)'                     && deny "git checkout làm mất thay đổi"
g 'checkout[[:space:]]+[^"'"'"']*[[:space:]](\.|--|-f|--force)([[:space:]]|$)' && deny "git checkout làm mất thay đổi"
g 'restore([[:space:]]|$)'                       && deny "git restore (mất thay đổi)"
printf '%s' "$cmd" | grep -qE "(^|[^[:alnum:]_])git\b[^\"'|;&]*[[:space:]]branch[[:space:]]+[^\"'|;&]*(-D|--delete[[:space:]]+--force)\b" && deny "git branch -D (xoá nhánh, mất commit)"
g 'commit[[:space:]]+[^"'"'"']*--amend\b'        && deny "git commit --amend (viết lại lịch sử)"
g 'rebase([[:space:]]|$)'                        && deny "git rebase (viết lại lịch sử)"
g 'filter-(branch|repo)\b'                       && deny "git filter-branch/filter-repo"
g 'reflog[[:space:]]+expire\b'                   && deny "git reflog expire"
g 'gc[[:space:]]+[^"'"'"']*--prune'              && deny "git gc --prune"
g 'update-ref[[:space:]]+[^"'"'"']*-d\b'         && deny "git update-ref -d"

exit 0
