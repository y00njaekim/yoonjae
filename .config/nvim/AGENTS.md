# Instructions

- Treat this repository's `.config/nvim` as the source of truth; sync changed files to `$HOME/.config/nvim`.
- Install external dependencies with the OS-appropriate package manager. Homebrew examples:

  - `brew install neovim`
  - `brew install ripgrep` — Telescope `live_grep`
  - `brew install tree-sitter-cli` — Tree-sitter parsers

# Python DAP

Where a setting goes is decided by the DAP protocol, not by taste.

- `launch` arguments → project `.vscode/launch.json`, read automatically from `getcwd()`.
  `program`, `cwd`, `python`, `args`, `env`, `console`, `justMyCode`; `${workspaceFolder}` is nvim's cwd.
  Keep `"type": "python"` — dap-python registers only `dap.adapters.python`, so the `"debugpy"` that
  current VS Code docs use resolves to no adapter here. Both editors accept `"python"`.
- `setExceptionBreakpoints` → lua `dap.defaults.<type>.exception_breakpoints`; a separate request,
  not a launch argument, so launch.json cannot express it. `<type>` is the config's `type` field.
  Default `'default'` is the adapter's recommendation (debugpy: `uncaught`).
- `justMyCode` is a launch argument but gates those filters — stopping on an exception raised in an
  import or other library frame needs `"justMyCode": false` *and* `'raised'`.
- `.nvim.lua` via `'exrc'` holds both in one file, at the cost of executing project-supplied lua and
  eager-loading nvim-dap.

Mid-session, re-send the request. Each call replaces the whole set and needs an active session.

```vim
" stop only when the process dies from an unhandled exception — session default
:lua require('dap').set_exception_breakpoints({'uncaught'})

" also stop the moment any exception is raised, including ones a try/except swallows
" — noisy in code that catches broadly
:lua require('dap').set_exception_breakpoints({'raised','uncaught'})

" no exception stops at all; line breakpoints are unaffected
:lua require('dap').set_exception_breakpoints({})
```
