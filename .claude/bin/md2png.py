#!/usr/bin/env python3
"""Render a markdown file to PNG, with LaTeX math typeset by KaTeX.

usage: md2png.py INPUT.md OUTPUT.png

All settings come from ~/.claude/mdview.conf. Environment variables of the
same name override it, for one-off experiments.
"""

import os
import pathlib
import re
import shutil
import sys

CONF = pathlib.Path.home() / ".claude" / "mdview.conf"
DEFAULT_CONF = pathlib.Path(__file__).with_name("mdview.conf")


def settings() -> dict:
    """conf file < environment. Missing keys are an error, not a silent default."""
    values: dict[str, str] = {}
    path = CONF if CONF.is_file() else DEFAULT_CONF
    if path.is_file():
        for line in path.read_text().splitlines():
            line = line.strip()
            if not line or line.startswith("#") or "=" not in line:
                continue
            key, _, raw = line.partition("=")
            raw = raw.strip()
            if len(raw) >= 2 and raw[0] == raw[-1] and raw[0] in "'\"":
                raw = raw[1:-1]
            values[key.strip()] = raw
    values.update({k: v for k, v in os.environ.items() if k.startswith("MDVIEW_")})

    required = [
        "MDVIEW_FONT",
        "MDVIEW_SANS",
        "MDVIEW_TRACKING",
        "MDVIEW_THEME",
        "MDVIEW_WIDTH_SCALE",
        "MDVIEW_WIDTH_MIN",
        "MDVIEW_WIDTH_MAX",
    ]
    missing = [k for k in required if k not in values]
    if missing:
        raise SystemExit(f"missing in {path}: {', '.join(missing)}")
    return values


def column_width(cfg: dict) -> int:
    """Fit the column to the pane this is running in."""
    if "MDVIEW_WIDTH" in cfg:
        return int(cfg["MDVIEW_WIDTH"])
    cols = shutil.get_terminal_size(fallback=(100, 30)).columns
    w = cols * int(cfg["MDVIEW_WIDTH_SCALE"])
    return max(int(cfg["MDVIEW_WIDTH_MIN"]), min(int(cfg["MDVIEW_WIDTH_MAX"]), w))


# Math must survive the markdown pass — underscores and asterisks inside
# formulas would otherwise be eaten as emphasis. Stash, convert, restore.
MATH = re.compile(r"(\$\$.+?\$\$|\\\[.+?\\\]|\\\(.+?\\\)|\$[^$\n]+?\$)", re.S)


def render_html(md_text: str, cfg: dict) -> str:
    import markdown

    stash: list[str] = []

    def hold(m):
        stash.append(m.group(0))
        return f"\x00MATH{len(stash) - 1}\x00"

    body = markdown.markdown(
        MATH.sub(hold, md_text),
        extensions=["tables", "fenced_code", "sane_lists", "codehilite"],
        extension_configs={"codehilite": {"guess_lang": False}},
    )
    body = re.sub(r"\x00MATH(\d+)\x00", lambda m: stash[int(m.group(1))], body)

    dark = cfg["MDVIEW_THEME"] != "light"
    f = float(cfg["MDVIEW_FONT"])
    sans = cfg["MDVIEW_SANS"]
    track = cfg["MDVIEW_TRACKING"]
    width = column_width(cfg)
    pad = round(f * 2.4)

    try:
        from pygments.formatters import HtmlFormatter

        pyg_css = HtmlFormatter(style="monokai" if dark else "friendly").get_style_defs(
            ".codehilite"
        )
    except Exception:
        pyg_css = ""

    bg, fg, dim = (
        ("#16171a", "#e6e4e0", "#9a978f") if dark else ("#fdfdfc", "#22201d", "#6b6862")
    )
    panel, rule = ("#202226", "#31343a") if dark else ("#f2f1ee", "#e0dedb")

    return f"""<!doctype html><meta charset="utf-8">
<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/katex@0.16.11/dist/katex.min.css">
<style>
  body {{ margin:0; padding:{pad}px {round(pad * 1.15)}px; width:{width}px; box-sizing:border-box;
         background:{bg}; color:{fg};
         font:{f}px/1.7 {sans}; letter-spacing:{track};
         -webkit-font-smoothing:antialiased; }}
  h1,h2,h3,h4 {{ line-height:1.3; font-weight:600; margin:1.7em 0 .55em; }}
  h1 {{ font-size:{round(f * 1.6, 1)}px; }}
  h2 {{ font-size:{round(f * 1.26, 1)}px; }}
  h3 {{ font-size:{round(f * 1.07, 1)}px; }}
  h4 {{ font-size:{f}px; color:{dim}; }}
  :first-child {{ margin-top:0; }}
  p, li {{ margin:.7em 0; }}
  ul, ol {{ padding-left:1.4em; }}
  a {{ color:inherit; text-underline-offset:3px; }}
  code {{ font:{round(f * 0.86, 1)}px/1.6 ui-monospace,"SF Mono",Menlo,monospace;
          background:{panel}; padding:2px 5px; border-radius:5px; }}
  pre {{ background:{panel}; padding:{round(f)}px {round(f * 1.15)}px; border-radius:9px;
         overflow-x:auto; margin:1.1em 0; }}
  pre code {{ background:none; padding:0; }}
  blockquote {{ margin:1.1em 0; padding:.1em 0 .1em 1.1em;
                border-left:3px solid {rule}; color:{dim}; }}
  table {{ border-collapse:collapse; width:100%; margin:1.1em 0;
           font-size:{round(f * 0.94, 1)}px; }}
  th, td {{ text-align:left; padding:{round(f * 0.6)}px {round(f * 0.8)}px;
            border-bottom:1px solid {rule}; }}
  th {{ font-weight:500; color:{dim}; font-size:{round(f * 0.85, 1)}px; }}
  hr {{ border:0; border-top:1px solid {rule}; margin:2em 0; }}
  .katex-display {{ margin:1.3em 0; }}
  {pyg_css}
</style>
{body}
<script src="https://cdn.jsdelivr.net/npm/katex@0.16.11/dist/katex.min.js"></script>
<script src="https://cdn.jsdelivr.net/npm/katex@0.16.11/dist/contrib/auto-render.min.js"></script>
<script>
  renderMathInElement(document.body, {{ throwOnError: false, delimiters: [
    {{left:"$$", right:"$$", display:true}},  {{left:"\\\\[", right:"\\\\]", display:true}},
    {{left:"$",  right:"$",  display:false}}, {{left:"\\\\(", right:"\\\\)", display:false}}
  ]}});
  document.fonts.ready.then(() => {{ window.__ready = true; }});
</script>"""


def main() -> int:
    if len(sys.argv) != 3:
        print(__doc__.strip(), file=sys.stderr)
        return 2
    src, out = pathlib.Path(sys.argv[1]), sys.argv[2]
    if not src.is_file() or not src.read_text().strip():
        print("nothing to render", file=sys.stderr)
        return 1

    cfg = settings()
    html = render_html(src.read_text(), cfg)

    from playwright.sync_api import sync_playwright

    with sync_playwright() as p:
        browser = p.chromium.launch()
        page = browser.new_page(
            viewport={"width": column_width(cfg), "height": 600}, device_scale_factor=2
        )
        page.set_content(html, wait_until="load")
        try:
            page.wait_for_function("window.__ready === true", timeout=8000)
        except Exception:
            pass  # CDN slow or offline — screenshot what we have
        page.screenshot(path=out, full_page=True)
        browser.close()
    return 0


if __name__ == "__main__":
    sys.exit(main())
