# Codex 답변 렌더링

Codex용 파일은 모두 `.codex` 아래에 둔다. Claude 설치는 필요하지 않다.

- hook 설정: `~/.codex/hooks.json`
- 실행 파일: `~/.codex/bin/mdview-state.py`, `mdview.sh`, `md2png.py`
- 렌더링 설정: `~/.codex/mdview.conf`
- Python 환경: `~/.codex/venv`
- 답변: `~/.codex/last-message/threads/{session_id}/latest.md`

## 설치

이 폴더의 `bin/`, `mdview.conf`, `hooks.json`을 사용자 `~/.codex/`에 배치한다.
기존 hooks.json이 있으면 이벤트별 배열에 병합한다.

```bash
python3 -m venv ~/.codex/venv
~/.codex/venv/bin/pip install playwright markdown pygments
~/.codex/venv/bin/playwright install chromium
```

`kitten`과 tmux, 이미지 표시가 가능한 터미널이 필요하다.
저장소 `.tmux.conf`의 `bind-key g` 설정과 `allow-passthrough on`을 적용하고
`tmux source-file ~/.tmux.conf`로 다시 읽는다.
Codex를 재시작하고 hook 검토가 표시되면 `/hooks`에서 확인 후 신뢰한다.

`Ctrl+A` 다음 `g`는 원래 pane의 `@mdview-thread`를 보고 Codex/Claude 뷰어를 선택한다.
Codex는 SessionStart/UserPromptSubmit에서 연결하고 Stop에서 답변을 저장한다.
현재 대화의 답변이 없으면 안내를 표시한다. 다른 대화의 답변으로 폴백하지 않는다.

기존 `.claude/last-message/threads/codex/`의 캐시는 자동 이동하지 않는다.
다음 답변 완료부터 새 경로에 저장한다. 수동 파일 열기:

```bash
bash ~/.codex/bin/mdview.sh /path/to/answer.md
```

공식 hook 규격: https://learn.chatgpt.com/docs/hooks
