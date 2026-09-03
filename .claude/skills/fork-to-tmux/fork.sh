#!/usr/bin/env bash
# 현재 Claude Code 세션을 tmux pane 에 fork 해서 띄운다. 대상이 없으면 세션·윈도우·pane 을 만든다.
# 사용: fork.sh <session:window[.pane]> [cwd] [--dry-run]
#   세션 ID 는 Claude Code 가 Bash 에 넣어 주는 CLAUDE_CODE_SESSION_ID 에서 읽는다.
#   --dry-run: 대상은 만들되 claude 를 띄우는 키 입력은 보내지 않는다.
set -euo pipefail

dry=0
args=()
for a in "$@"; do
  case "$a" in --dry-run) dry=1 ;; *) args+=("$a") ;; esac
done
target="${args[0]:?사용: fork.sh <session:window[.pane]> [cwd] [--dry-run]}"
cwd="${args[1]:-$PWD}"
sid="${CLAUDE_CODE_SESSION_ID:-}"

if [ -z "$sid" ] && [ "$dry" -eq 0 ]; then
  echo "CLAUDE_CODE_SESSION_ID 가 비어 있다. Claude Code 세션 안의 Bash 에서 실행해야 한다." >&2
  exit 1
fi
case "$target" in
  *:*) ;;
  *) echo "대상은 session:window[.pane] 형식이어야 한다: '$target'" >&2; exit 1 ;;
esac
sess="${target%%:*}"
rest="${target#*:}"
win="${rest%%.*}"
pane="${rest#*.}"
[ "$pane" = "$rest" ] && pane=0   # '.pane' 이 없으면 0
target="$sess:$win.$pane"

made=()
if ! tmux has-session -t "=$sess" 2>/dev/null; then
  tmux new-session -d -s "$sess" -c "$cwd"
  made+=("세션 $sess")
fi
if ! tmux list-windows -t "=$sess" -F '#{window_index}' | grep -qx -- "$win"; then
  tmux new-window -d -t "=$sess:$win" -c "$cwd"
  made+=("윈도우 $sess:$win")
fi
while ! tmux list-panes -t "=$sess:$win" -F '#{pane_index}' | grep -qx -- "$pane"; do
  n=$(tmux list-panes -t "=$sess:$win" | wc -l | tr -d ' ')
  if [ "$n" -gt "$pane" ]; then
    echo "윈도우 $sess:$win 에 pane $pane 을 만들 수 없다 (인덱스가 비연속). 있는 pane: $(tmux list-panes -t "=$sess:$win" -F '#{pane_index}' | tr '\n' ' ')" >&2
    exit 2
  fi
  tmux split-window -d -t "=$sess:$win" -c "$cwd"
  made+=("pane $sess:$win.$(tmux list-panes -t "=$sess:$win" -F '#{pane_index}' | sort -n | tail -1)")
done
[ ${#made[@]} -gt 0 ] && echo "만듦: ${made[*]}"

running=$(tmux display-message -p -t "=$target" '#{pane_current_command}')
case "$running" in
  zsh|bash|fish|sh) ;;
  *) echo "pane '$target' 에서 '$running' 이 실행 중이라 키를 보내지 않는다. 셸 프롬프트 상태의 pane 을 지정할 것." >&2; exit 3 ;;
esac

if [ "$dry" -eq 1 ]; then
  echo "dry-run: tmux $target 에 'cd $cwd && claude --resume ${sid:-<id>} --fork-session' 을 보낼 것"
  exit 0
fi
tmux send-keys -t "=$target" "cd $(printf %q "$cwd") && claude --resume $sid --fork-session" Enter
echo "fork 완료: 세션 $sid → tmux $target (cwd $cwd)"
