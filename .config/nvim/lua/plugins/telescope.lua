local mapKey = require("utils.keyMapper").mapKey

return {
    'nvim-telescope/telescope.nvim', version = '*',
    dependencies = {
        'nvim-lua/plenary.nvim',
        'nvim-telescope/telescope-ui-select.nvim',
        'nvim-telescope/telescope-live-grep-args.nvim',
    },
    config = function()
        local telescope = require("telescope")

        telescope.setup({
            extensions = {
                ["ui-select"] = require("telescope.themes").get_dropdown({}),
            },
        })
        telescope.load_extension("ui-select")
        telescope.load_extension("live_grep_args")

        local builtin = require("telescope.builtin")
        mapKey('<leader>ff', builtin.find_files)
        mapKey('<leader>fg', telescope.extensions.live_grep_args.live_grep_args)
        mapKey('<leader>fb', builtin.buffers)
        mapKey('<leader>fh', builtin.help_tags) 
        mapKey('grr', builtin.lsp_references)
    end,
}
