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
    end,
  },
}
