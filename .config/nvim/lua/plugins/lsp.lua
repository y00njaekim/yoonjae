return {
  {
    "mason-org/mason-lspconfig.nvim",
    opts = {
      ensure_installed = { "jsonls", "lua_ls", "pyright" },
      automatic_enable = { "jsonls", "lua_ls", "pyright" },
    },
    dependencies = {
      { "mason-org/mason.nvim", opts = {} },
      "b0o/schemastore.nvim",
      "neovim/nvim-lspconfig",
    },
    config = function(_, opts)
      vim.lsp.config("jsonls", {
        settings = {
          json = {
            schemas = require("schemastore").json.schemas(),
            validate = { enable = true },
          },
        },
      })

      require("mason-lspconfig").setup(opts)

      local group = vim.api.nvim_create_augroup("user_lsp_keymaps", { clear = true })

      vim.api.nvim_create_autocmd("LspAttach", {
        group = group,
        callback = function(args)
          local client = assert(vim.lsp.get_client_by_id(args.data.client_id))
          local map_opts = { buffer = args.buf, silent = true }

          vim.keymap.set("n", "K", vim.lsp.buf.hover, map_opts)
          vim.keymap.set("n", "gd", vim.lsp.buf.definition, map_opts)
          vim.keymap.set({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, map_opts)

          if client:supports_method("textDocument/foldingRange") then
            for _, win in ipairs(vim.fn.win_findbuf(args.buf)) do
              vim.wo[win].foldmethod = "expr"
              vim.wo[win].foldexpr = "v:lua.vim.lsp.foldexpr()"
              vim.wo[win].foldtext = "v:lua.vim.lsp.foldtext()"
            end
          end

          if client:supports_method("textDocument/completion") then
            vim.lsp.completion.enable(true, client.id, args.buf, {
              autotrigger = true,
            })

            vim.keymap.set("i", "<C-Space>", vim.lsp.completion.get, map_opts)

            vim.keymap.set({ "i", "s" }, "<Tab>", function()
              if vim.fn.pumvisible() == 1 then
                return "<C-n>"
              end
              if vim.snippet.active({ direction = 1 }) then
                return "<Cmd>lua vim.snippet.jump(1)<CR>"
              end
              return "<Tab>"
            end, { buffer = args.buf, expr = true, silent = true })

            vim.keymap.set({ "i", "s" }, "<S-Tab>", function()
              if vim.fn.pumvisible() == 1 then
                return "<C-p>"
              end
              if vim.snippet.active({ direction = -1 }) then
                return "<Cmd>lua vim.snippet.jump(-1)<CR>"
              end
              return "<S-Tab>"
            end, { buffer = args.buf, expr = true, silent = true })

            vim.keymap.set("i", "<CR>", function()
              local completion = vim.fn.complete_info({ "selected" })
              if vim.fn.pumvisible() == 1 and completion.selected >= 0 then
                return "<C-y>"
              end
              return "<CR>"
            end, { buffer = args.buf, expr = true, silent = true })
          end
        end,
      })
    end,
  },
}
