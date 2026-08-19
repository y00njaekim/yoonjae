#!/usr/bin/env bash
# Render the last Claude Code answer as a typeset image in this pane.
# usage: mdview.sh [FILE.md]
# All tunables live in ~/.claude/mdview.conf

src="${1:-$HOME/.claude/last-message/latest.md}"
png="$HOME/.claude/last-message/latest.png"

if ! "$HOME/.claude/venv/bin/python" "$HOME/.claude/bin/md2png.py" "$src" "$png"; then
  echo "render failed" >&2
  exit 1
fi

clear
kitten icat --align left --transfer-mode=stream "$png"

# tmux draws the placeholder cells but doesn't always repaint them, so nudge it.
[ -n "$TMUX" ] && tmux refresh-client
