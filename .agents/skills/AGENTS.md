# skills

이 폴더의 스킬은 실체가 여기 있고, `$HOME/.agents/skills/`에는 이곳을 가리키는 symlink를 둔다. 여기서 관리하려는 스킬은 이 폴더에 만든다.

동기화는 이 폴더 → `$HOME` 한 방향이다. `$HOME/.agents/skills/`에 실체로 있는 다른 스킬들은 이 폴더와 무관하니 그대로 둔다.

## 링크 동기화

이 폴더의 스킬을 추가·이름 변경·삭제한 뒤 실행한다. 이 폴더의 `SKILL.md`를 가진 모든 하위 디렉터리가 `$HOME/.agents/skills/<이름>` symlink로 존재하고, 이 폴더를 가리키던 끊긴 링크가 하나도 안 남았으면 끝난 것이다.

1. **이 문서가 있는 폴더로 이동해 링크를 건다.**

   ```bash
   for d in */SKILL.md; do
     [ -f "$d" ] || continue
     n=${d%/SKILL.md}
     ln -sfn "$PWD/$n" "$HOME/.agents/skills/$n"
   done
   ```

   `Is a directory` 로 실패하면 같은 이름의 실물 스킬이 `$HOME` 쪽에 따로 있다는 뜻이다. 어느 쪽을 남길지 사용자에게 묻고 정리한다.

2. **이 폴더를 가리키던 끊긴 링크를 지운다.**

   ```bash
   for l in "$HOME"/.agents/skills/*; do
     [ -e "$l" ] && continue
     case "$(readlink "$l")" in "$PWD"/*) echo "끊긴 링크: $l";; esac
   done
   ```

   목록에 뜬 것이 이 폴더에서 지운 스킬인지 확인하고 `rm` 한다.
