return {
  {
    "goolord/alpha-nvim",
    event = "VimEnter",
    dependencies = {
      "nvim-tree/nvim-web-devicons",
    },
    config = function()
      local alpha = require("alpha")
      local dashboard = require("alpha.themes.dashboard")

      dashboard.section.header.val = {
        [[███╗   ██╗██╗   ██╗██╗███╗   ███╗]],
        [[████╗  ██║██║   ██║██║████╗ ████║]],
        [[██╔██╗ ██║██║   ██║██║██╔████╔██║]],
        [[██║╚██╗██║╚██╗ ██╔╝██║██║╚██╔╝██║]],
        [[██║ ╚████║ ╚████╔╝ ██║██║ ╚═╝ ██║]],
        [[╚═╝  ╚═══╝  ╚═══╝  ╚═╝╚═╝     ╚═╝]],
      }
      dashboard.section.header.opts.hl = "Function"

      dashboard.section.buttons.val = {
        dashboard.button("n", "  New file", "<cmd>enew<CR><cmd>startinsert<CR>"),
        dashboard.button("f", "󰈞  Find file", "<cmd>Telescope find_files<CR>"),
        dashboard.button("w", "󰊄  Find word", "<cmd>Telescope live_grep<CR>"),
        dashboard.button("r", "  Recent files", "<cmd>Telescope oldfiles<CR>"),
        dashboard.button("q", "󰅚  Quit", "<cmd>qa<CR>"),
      }

      local stats = require("lazy").stats()
      dashboard.section.footer.val = string.format(
        "Press a shortcut to get started  •  Neovim v%d.%d.%d  •  %d/%d plugins in %.2f ms",
        vim.version().major,
        vim.version().minor,
        vim.version().patch,
        stats.loaded,
        stats.count,
        stats.startuptime
      )
      dashboard.section.footer.opts.hl = "Comment"

      dashboard.config.layout = {
        { type = "padding", val = 2 },
        dashboard.section.header,
        { type = "padding", val = 2 },
        dashboard.section.buttons,
        { type = "padding", val = 1 },
        dashboard.section.footer,
      }

      alpha.setup(dashboard.config)

      -- BufDelete 시점엔 닫히는 버퍼가 아직 목록에 남아 있어 schedule 로 미룬다
      vim.api.nvim_create_autocmd("BufDelete", {
        group = vim.api.nvim_create_augroup("alpha_on_last_buf_delete", { clear = true }),
        callback = function()
          vim.schedule(function()
            local remaining = vim.tbl_filter(function(buf)
              return vim.bo[buf].buflisted and vim.api.nvim_buf_get_name(buf) ~= ""
            end, vim.api.nvim_list_bufs())

            -- 이미 alpha 면 재진입 금지 — startup 에 alpha 가 초기 [No Name] 버퍼를
            -- 지우면서 이 autocmd 를 깨우고, 재시작하면 빈 버퍼만 남는다
            if vim.bo.filetype == "alpha" then
              return
            end

            -- 보조 창이 떠 있으면 레이아웃 유지
            if #remaining > 0 or #vim.api.nvim_tabpage_list_wins(0) > 1 then
              return
            end
            vim.cmd("Alpha")
          end)
        end,
      })
    end,
  },
}
