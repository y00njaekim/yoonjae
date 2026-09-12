#!/usr/bin/env bash
# Usage: mdview.sh --pane %ID | mdview.sh FILE.md
set -euo pipefail
base=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
if [[ "${1:-}" == --pane && $# == 2 ]]; then
  src=$(python3 "$base/mdview-state.py" resolve "$2")
elif [[ $# == 1 ]]; then
  src=$1
elif [[ $# == 0 && -n "${TMUX_PANE:-}" ]]; then
  src=$(python3 "$base/mdview-state.py" resolve "$TMUX_PANE")
else
  echo 'usage: mdview.sh --pane %ID | mdview.sh FILE.md' >&2
  exit 1
fi
# Each viewer gets its own snapshot and PNG, even for simultaneous opens.
work=$(mktemp -d "${TMPDIR:-/tmp}/mdview.XXXXXXXX")
trap 'rm -rf -- "$work"' EXIT
cp -- "$src" "$work/answer.md"
"${MDVIEW_PYTHON:-$HOME/.codex/venv/bin/python}" "$base/md2png.py" "$work/answer.md" "$work/answer.png"
clear
kitten icat --align left --transfer-mode=stream "$work/answer.png"
if [[ -n "${TMUX:-}" ]]; then tmux refresh-client; fi
