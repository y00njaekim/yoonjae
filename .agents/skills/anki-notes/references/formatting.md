# 노트 포맷 규칙

미리보기 md와 실제 투입 필드 값 모두 이 규칙을 따른다.

## 필드 공통

- 필드 내 줄바꿈은 반드시 `<br>`. 실제 줄바꿈(개행 문자)은 사용 금지.
- 모든 수식은 `\( \pm \)` 같은 MathJax inline 형식.
- bold, italic, underline 등 모든 서식 효과는 HTML 태그로.
- 어미는 구어체(~입니다, ~합니다) 금지 — 명사형 종결, ~임, ~함.
- jargon은 영어로 표현.

## Cloze

- `c1`만 사용. `c2`–`c9` 금지.
- 빈칸은 3단어 이하. 긴 문장·구에 만들지 않는다.
- MathJax 외부에만 건다: `{{c1::\( \pm \)}}` 형태. MathJax 내부에 cloze를 넣지 않는다.

## 코드

- 여러 줄이면 `<pre>`, 짧은 inline이면 `<code>`.
- `<span style="color: ...">`로 최소한의 syntax highlighting:
  - keyword/control-flow: `rgb(119, 0, 136)`
  - function/class name: `rgb(0, 0, 255)`
  - type/built-in: `rgb(51, 0, 170)`
  - operator: `rgb(152, 26, 26)`

## 각주

- 배경지식을 넘는 용어·개념 옆에 `<sup>[1]</sup>` 형식의 HTML 위첨자.
- 앞면에 나온 용어는 앞면 본문 하단에, 뒷면에 나온 용어는 뒷면 본문 하단에 각주 설명 블럭 — `<hr>`로 구분한 뒤 `<small>` 태그로 감싼다.
