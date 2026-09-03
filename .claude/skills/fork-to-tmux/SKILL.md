---
name: fork-to-tmux
description: 현재 Claude 세션을 지정한 tmux pane 에 fork 해서 띄운다. "/fork-to-tmux 1:2.1" 처럼 session:window.pane 을 받는다. "이 세션 fork 해서 tmux 에 띄워줘" 요청에 쓴다.
---

인자로 받은 tmux 대상(`session:window[.pane]`)에 지금 세션의 fork 를 띄운다. 대상이 없으면 만들어서 띄운다.

1. 대상이 주어졌으면 바로 실행한다.
   ```
   ~/.claude/skills/fork-to-tmux/fork.sh <대상>
   ```
   스크립트가 세션 ID(`CLAUDE_CODE_SESSION_ID`)와 cwd 를 알아서 채우고, 대상 pane 이 셸 프롬프트일 때만 `claude --resume <id> --fork-session` 을 보낸다.
2. 대상 세션·윈도우·pane 이 없으면 스크립트가 만든다(세션은 detached 로, pane 은 split 으로). `.pane` 을 생략하면 0 이다. 스크립트가 만든 것은 "만듦:" 줄로 알려 준다.
3. 완료 기준: 스크립트가 "fork 완료" 를 찍고, `tmux capture-pane -t <대상> -p` 에 claude 프롬프트가 보인다. 그 한 줄만 보고한다.
