#!/usr/bin/env python3
"""Thread-scoped answer storage and tmux pane association for Claude/Codex."""
import argparse
import json
import os
from pathlib import Path
import re
import subprocess
import sys
import tempfile

ROOT = Path.home()

def answer_path(key):
    provider, sid = key.split('/', 1)
    override = os.environ.get('MDVIEW_STATE_DIR')
    base = Path(override) / provider if override else ROOT / ('.' + provider) / 'last-message'
    return base / 'threads' / sid / 'latest.md'

OPTION = '@mdview-thread'


def atomic_write(path, text):
    path.parent.mkdir(parents=True, exist_ok=True)
    fd, name = tempfile.mkstemp(dir=path.parent)
    try:
        with os.fdopen(fd, 'w', encoding='utf-8') as stream:
            stream.write(text)
        os.replace(name, path)
    finally:
        if os.path.exists(name):
            os.unlink(name)


def tmux(*args):
    return subprocess.check_output(['tmux', *args], text=True, stderr=subprocess.DEVNULL).strip()


def key_for(provider, sid):
    if not isinstance(sid, str) or not re.fullmatch(r'[A-Za-z0-9_-]+', sid):
        raise ValueError('Missing or invalid session ID')
    return provider + '/' + sid


def answer_text(value):
    if isinstance(value, str):
        return value
    if isinstance(value, list):
        return '\n\n'.join(x['text'] for x in value
                           if isinstance(x, dict) and x.get('type') == 'text'
                           and isinstance(x.get('text'), str))
    return ''


def claude_transcript(path):
    last = ''
    with open(path, encoding='utf-8') as stream:
        for line in stream:
            try:
                item = json.loads(line)
            except json.JSONDecodeError:
                continue
            if item.get('type') == 'assistant':
                text = answer_text(item.get('message', {}).get('content'))
                if text.strip():
                    last = text
    return last


def capture(provider, payload):
    # Subagents must never change the parent pane's selected conversation.
    if payload.get('agent_id') or payload.get('hook_event_name') in {'SubagentStart', 'SubagentStop'}:
        return
    event = payload.get('hook_event_name', 'Stop')
    if event not in {'SessionStart', 'UserPromptSubmit', 'SessionEnd', 'Stop'}:
        return
    key = key_for(provider, payload.get('session_id'))
    pane = os.environ.get('TMUX_PANE') if os.environ.get('TMUX') else None
    if pane:
        current = tmux('show-options', '-pqv', '-t', pane, OPTION)
        if event in {'SessionStart', 'UserPromptSubmit'} or (event == 'Stop' and not current):
            tmux('set-option', '-p', '-t', pane, OPTION, key)
        elif event == 'SessionEnd' and current == key:
            tmux('set-option', '-pu', '-t', pane, OPTION)
    if event != 'Stop':
        return
    text = answer_text(payload.get('last_assistant_message'))
    if not text.strip() and provider == 'claude' and payload.get('transcript_path'):
        text = claude_transcript(payload['transcript_path'])
    if text.strip():
        atomic_write(answer_path(key), text + '\n')


def resolve(pane):
    key = tmux('show-options', '-pqv', '-t', pane, OPTION)
    if not re.fullmatch(r'(claude|codex)/[A-Za-z0-9_-]+', key):
        raise ValueError('이 pane에 연결된 대화가 없습니다. hook 등록 후 대화를 시작하세요.')
    path = answer_path(key)
    if not path.is_file():
        raise ValueError('현재 대화에 저장된 답변이 아직 없습니다. 답변 완료 후 다시 누르세요.')
    return path


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    sub = parser.add_subparsers(dest='command', required=True)
    hook = sub.add_parser('capture')
    hook.add_argument('provider', choices=['claude', 'codex'])
    view = sub.add_parser('resolve')
    view.add_argument('pane')
    args = parser.parse_args()
    if args.command == 'capture':
        capture(args.provider, json.load(sys.stdin))
        print('{}')
    else:
        print(resolve(args.pane))


if __name__ == '__main__':
    try:
        main()
    except (OSError, ValueError, subprocess.CalledProcessError) as exc:
        print(f'mdview: {exc}', file=sys.stderr)
        sys.exit(1)
