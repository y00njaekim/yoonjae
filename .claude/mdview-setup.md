# Claude Code 답변을 터미널에 조판해서 보기

Claude Code의 답변을 마크다운 원본에서 다시 조판해, 이미지로 터미널 패널에 띄운다.
Ghostty + tmux 환경 기준.

## 원리

Claude Code의 TUI 출력은 이미 렌더링이 끝난 결과물이라 손댈 수 없다.
대신 그 **위쪽에 있는 마크다운 원본**을 잡아서 따로 조판한다.

```
Stop hook ─→ latest.md ─→ [헤드리스 크롬] ─→ PNG ─→ [kitten icat] ─→ tmux 패널
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
| `~/.claude/hooks/render-last.sh` | Stop hook. 마지막 답변을 `latest.md`로 저장 |

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

## 5. Stop hook

`~/.claude/hooks/render-last.sh`:

```bash
#!/usr/bin/env bash
set -uo pipefail
out=~/.claude/last-message; mkdir -p "$out"
in=$(cat)

msg=$(jq -r '.last_assistant_message
  | if type=="string" then .
    elif type=="array" then ([.[]|select(.type=="text")|.text]|join("\n\n"))
    else "" end' <<<"$in")

if [ -z "$msg" ]; then
  t=$(jq -r '.transcript_path' <<<"$in")
  msg=$(tac "$t" | jq -r 'select(.type=="assistant")
    | [.message.content[]?|select(.type=="text")|.text] | join("\n\n")' \
    2>/dev/null | grep -m1 -v '^$' || true)
fi

printf '%s\n' "$msg" > "$out/latest.md"
exit 0
```

```bash
chmod +x ~/.claude/hooks/render-last.sh
brew install jq
```

`~/.claude/settings.json`에 등록:

```json
{
  "hooks": {
    "Stop": [
      {
        "hooks": [
          { "type": "command", "command": "~/.claude/hooks/render-last.sh" }
        ]
      }
    ]
  }
}
```

경로를 추측하지 않는 게 핵심이다. hook이 `transcript_path`를 직접 넘겨주므로
Claude Code 버전이 바뀌어도 안 깨진다.

## 6. tmux 키 바인딩

```
bind-key g split-window -h "~/.claude/bin/mdview.sh; read -r _"
```

```bash
tmux source-file ~/.tmux.conf
```

`prefix + g` → 오른쪽 패널에 조판된 마지막 답변. 엔터로 닫기.

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

## 아직 안 푼 것

- **패널별 분리** — Claude Code를 여러 개 띄우면 `latest.md`를 공유해서 섞인다.
  hook에서 `$TMUX_PANE`으로 파일명을 키잉하면 해결
