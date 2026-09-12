# Claude Code 답변을 터미널에 조판해서 보기

Claude Code의 답변을 마크다운 원본에서 다시 조판해, 이미지로 터미널 패널에 띄운다.
Ghostty + tmux 환경 기준.

## 원리

Claude Code의 TUI 출력은 이미 렌더링이 끝난 결과물이라 손댈 수 없다.
대신 그 **위쪽에 있는 마크다운 원본**을 잡아서 따로 조판한다.

```
Stop hook ─→ threads/provider/session_id/latest.md ─→ [헤드리스 크롬] ─→ PNG ─→ [kitten icat] ─→ tmux 패널
```

- 원본은 Claude Code가 남기는 세션 트랜스크립트(JSONL)에서 온다
- 조판은 브라우저 엔진을 빌려 쓴다 (가변폭 폰트 · 제목 크기 · 수식)
- 표시는 kitty 그래픽 프로토콜의 **unicode placeholder** 방식을 쓴다 → tmux 통과 가능

## 구성 파일

| 파일                             | 역할                                        |
| -------------------------------- | ------------------------------------------- |
| `~/.claude/mdview.conf`          | 설정 전부 (폰트 · 폭 · 테마)                |
| `~/.claude/bin/md2png.py`        | conf 읽고 마크다운 → PNG 조판               |
| `~/.claude/bin/mdview.sh`        | 렌더 호출 → 이미지 표시 → tmux 갱신         |
| `~/.claude/hooks/render-last.sh` | 대화 생명주기 hook. ID별 답변 저장 및 pane 연결 |

---

## 1. kitten 설치

이미지 전송에 kitty의 `kitten` 바이너리만 빌려 쓴다. kitty.app 자체는 안 쓴다.

```bash
brew install --cask kitty
ln -s /Applications/kitty.app/Contents/MacOS/kitten "$(brew --prefix)/bin/kitten"
```

## 2. tmux 통과 허용

```bash
# ~/.tmux.conf
set -g allow-passthrough on
```

## 3. 파이썬 환경

```bash
python3 -m venv ~/.claude/venv
~/.claude/venv/bin/pip install playwright markdown pygments
~/.claude/venv/bin/playwright install chromium
```

## 4. 파일 배치

```bash
mkdir -p ~/.claude/bin ~/.claude/hooks
# mdview.conf         → ~/.claude/
# md2png.py, mdview.sh → ~/.claude/bin/
chmod +x ~/.claude/bin/mdview.sh
```

## 5. 대화별 hook 등록 (Claude + Codex)

`bin/mdview-state.py`, `bin/mdview.sh`, `bin/md2png.py`를 `~/.claude/bin/`에,
`hooks/render-last.sh`를 `~/.claude/hooks/`에 배치한다.
Python 3은 상태 저장용이고, 기존 venv는 이미지 렌더링용이다.

이 저장소의 `.claude/settings.json`에 있는 `hooks` 항목을 사용자
`~/.claude/settings.json`에 병합한다. 기존 설정이나 다른 hook을 덮어쓰지 않는다.
Codex 실행 파일·설정·venv는 `.codex` 아래에서 독립적으로 관리한다.
[Codex 설치 안내](../.codex/mdview-setup.md)를 따른다.
Codex는 `.codex/hooks.json`을 `~/.codex/hooks.json`에 배치한다.
이미 hooks.json이 있으면 각 이벤트의 배열에 병합한다.
두 앱 모두 SessionStart / UserPromptSubmit / Stop / SessionEnd를 등록한다.
Codex에서 hook 검토가 표시되면 `/hooks`에서 정의를 확인하고 신뢰해야 실행된다.
설정을 적용한 다음 CLI를 다시 시작한다.

공식 Codex hook 규격: https://learn.chatgpt.com/docs/hooks

- 답변 저장: `~/.claude/last-message/threads/{session_id}/latest.md` (Claude),
  `~/.codex/last-message/threads/{session_id}/latest.md` (Codex)
- 현재 대화 연결: tmux pane option `@mdview-thread`
- 시작/프롬프트 시 pane 연결 갱신, 종료 시 해당 연결 해제
- Stop은 그 대화의 답변만 갱신. 이전 대화의 늦은 Stop은 새 연결을 덮어쓰지 않음
- Claude는 답변 필드가 없으면 전달받은 transcript에서 마지막 텍스트를 읽음
- Codex는 Stop의 `last_assistant_message`를 사용
- 답변이 없거나 연결되지 않은 pane은 안내 메시지를 표시
- 전체 세션 공용 `latest.md`로 폴백하지 않음

## 6. tmux 키 바인딩

```tmux
bind-key g run-shell 'case "#{@mdview-thread}" in codex/*) app=codex ;; *) app=claude ;; esac; tmux split-window -h -t "#{pane_id}" "bash ~/.$app/bin/mdview.sh --pane #{pane_id}; read -r _"'
```

`~/.tmux.conf`에 위 설정을 반영하고 `tmux source-file ~/.tmux.conf`로 재로딩한다.
`Ctrl+A` 다음 `g`를 누르면 **누른 원래 pane의 대화**에서 마지막 답변을 오른쪽에 표시한다.
각 뷰어는 별도의 임시 Markdown/PNG를 사용하므로 동시에 열어도 충돌하지 않는다.
엔터로 닫는다. 렌더링 실패 시에도 패널에 오류가 남는다.

명시적인 파일은 `bash ~/.claude/bin/mdview.sh /path/to/answer.md`로 볼 수 있다.

이 기능은 tmux 안의 Claude Code / Codex CLI용이다. 데스크톱 채팅에는
`TMUX_PANE`이 없어 단축키를 연결할 수 없다. hook이 실행되면 ID별 저장은 가능하다.
동일 pane에서 새 대화로 바꾼 경우 SessionStart 또는 UserPromptSubmit 이후 연결된다.

---

## 설정

`~/.claude/mdview.conf` 한 곳에서만 조절한다.
키가 빠지면 조용히 기본값으로 넘어가지 않고 에러를 낸다 — 설정이 두 군데
살아있는 상황을 막기 위해서다.

```bash
MDVIEW_FONT=12                # 본문 크기. 나머지가 비례로 따라옴
MDVIEW_SANS='"Helvetica Neue","Apple SD Gothic Neo",sans-serif'
MDVIEW_TRACKING=-0.012em      # 음수일수록 자간이 좁아짐
MDVIEW_WIDTH_SCALE=9          # 폭 = 패널 컬럼 수 × SCALE
MDVIEW_WIDTH_MIN=640
MDVIEW_WIDTH_MAX=1100
MDVIEW_THEME=dark
```

일회성 실험은 환경변수로 덮어쓴다:

```bash
MDVIEW_FONT=16 ~/.claude/bin/mdview.sh
```

---

## 겪었던 문제들

**이미지가 바로 안 뜨고 `prefix + [` 같은 걸 해야 뜸**
tmux가 placeholder 셀을 그려놓고 다시 칠하지 않아서다.
`mdview.sh` 끝의 `tmux refresh-client`가 이걸 대신한다.

**패널이 뜨자마자 사라짐**
tmux가 명령을 `sh`로 돌리는데 `read -n1`은 bash 문법이라 실패한다.
`read -r _`를 쓴다 (엔터로 닫힘).

**폰트가 세리프로 나옴**
conf 파서가 `.strip("'\"")`로 따옴표를 벗기면 바깥 작은따옴표에서 멈추지 않고
안쪽 큰따옴표까지 먹어서 CSS가 깨졌다. 지금은 짝이 맞는 한 겹만 벗긴다.

**수식이 깨짐**
마크다운 변환이 `$x_1$`의 `_`를 강조 문법으로 먹는다.
`md2png.py`는 수식을 미리 빼돌렸다가 변환 후 되돌린다.

## 검증

`python3 -m unittest discover -s tests -p "test_mdview*.py"`
대화/프로바이더 분리, pane 전환, 늦게 끝난 이전 대화, 여러 줄 transcript 복구를 검사한다.
