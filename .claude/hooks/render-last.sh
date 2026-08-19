#!/usr/bin/env bash
set -uo pipefail
out=~/.claude/last-message; mkdir -p "$out"
in=$(cat)

# 우선 last_assistant_message (string / content array 둘 다 처리)
msg=$(jq -r '.last_assistant_message
  | if type=="string" then .
    elif type=="array" then ([.[]|select(.type=="text")|.text]|join("\n\n"))
    else "" end' <<<"$in")

# 없거나 비면 transcript에서 마지막 assistant text 블록으로 폴백
if [ -z "$msg" ]; then
  t=$(jq -r '.transcript_path' <<<"$in")
  msg=$(tac "$t" | jq -r 'select(.type=="assistant")
    | [.message.content[]?|select(.type=="text")|.text] | join("\n\n")' \
    2>/dev/null | grep -m1 -v '^$' || true)
fi

printf '%s\n' "$msg" > "$out/latest.md"

exit 0
