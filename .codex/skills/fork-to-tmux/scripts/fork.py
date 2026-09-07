#!/usr/bin/env python3
"""Fork the current Codex thread into a tmux pane."""
import argparse
import os
from pathlib import Path
import re
import shlex
import shutil
import subprocess
import sys
import uuid


def tmux(*args):
    return subprocess.check_output(['tmux', *args], text=True).strip()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('target', help='session:window[.pane]; window/pane are numeric')
    parser.add_argument('--cwd', default=os.getcwd())
    parser.add_argument('--session-id', default=os.environ.get('CODEX_THREAD_ID'))
    parser.add_argument('--dry-run', action='store_true')
    args = parser.parse_args()
    match = re.fullmatch(r'([A-Za-z0-9_-]+):([0-9]+)(?:\.([0-9]+))?', args.target)
    if not match:
        parser.error('대상은 session:window[.pane] 형식이어야 합니다. window/pane은 숫자입니다.')
    session, window, pane = match.groups()
    window, pane = int(window), int(pane or 0)
    if not args.session_id:
        parser.error('CODEX_THREAD_ID가 없습니다. 현재 대화 ID를 --session-id로 전달하세요.')
    try:
        sid = str(uuid.UUID(args.session_id))
    except ValueError:
        parser.error('대화 ID는 UUID여야 합니다.')
    cwd = str(Path(args.cwd).resolve(strict=True))
    if not Path(cwd).is_dir():
        parser.error('--cwd는 디렉터리여야 합니다.')
    codex = shutil.which('codex')
    if not codex or not shutil.which('tmux'):
        parser.error('codex와 tmux가 PATH에 있어야 합니다.')
    command = shlex.join([codex, 'fork', sid, '--cd', cwd])
    target = f'{session}:{window}.{pane}'
    if args.dry_run:
        print(f'dry-run: tmux {target}\n명령: {command}')
        return
    existing = subprocess.run(['tmux', 'has-session', '-t', f'={session}'],
                              stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    if existing.returncode:
        tmux('new-session', '-d', '-s', session, '-c', cwd)
        print(f'만듦: 세션 {session}', flush=True)
    win_target = f'={session}:{window}'
    windows = tmux('list-windows', '-t', f'={session}', '-F', '#{window_index}').splitlines()
    if str(window) not in windows:
        tmux('new-window', '-d', '-t', win_target, '-c', cwd)
        print(f'만듦: 윈도우 {session}:{window}', flush=True)
    while True:
        indices = [int(x) for x in tmux('list-panes', '-t', win_target,
                                      '-F', '#{pane_index}').splitlines()]
        if pane in indices:
            break
        if pane < min(indices):
            raise RuntimeError(f'pane {pane}는 현재 pane-base-index보다 작습니다: {indices}')
        tmux('split-window', '-d', '-t', win_target, '-c', cwd)
        print(f'만듦: {session}:{window}에 pane 추가', flush=True)
    pane_id = tmux('display-message', '-p', '-t', f'={target}', '#{pane_id}')
    running = tmux('display-message', '-p', '-t', pane_id, '#{pane_current_command}')
    if running not in {'zsh', 'bash', 'fish', 'sh', 'dash', 'ksh'}:
        raise RuntimeError(f'{target}에서 {running!r} 실행 중: 입력을 보내지 않았습니다.')
    # Literal mode prevents command text from being interpreted as tmux key names.
    tmux('send-keys', '-t', pane_id, '-l', command)
    tmux('send-keys', '-t', pane_id, 'Enter')
    print(f'fork 명령 전달: 대화 {sid} → tmux {target} (cwd {cwd})')


if __name__ == '__main__':
    try:
        main()
    except (OSError, subprocess.CalledProcessError, RuntimeError) as exc:
        print(f'오류: {exc}', file=sys.stderr)
        sys.exit(1)
