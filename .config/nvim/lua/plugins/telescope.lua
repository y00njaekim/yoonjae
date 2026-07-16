local mapKey = require("utils.keyMapper").mapKey

return {
    'nvim-telescope/telescope.nvim', version = '*',
    dependencies = {
        'nvim-lua/plenary.nvim',
        -- optional but recommended
        { 'nvim-telescope/telescope-fzf-native.nvim', build = 'make' },
        'nvim-telescope/telescope-ui-select.nvim',
    },
    config = function()
        local telescope = require("telescope")

        telescope.setup({
            extensions = {
                ["ui-select"] = require("telescope.themes").get_dropdown({}),
            },
        })
        telescope.load_extension("ui-select")

        local builtin = require("telescope.builtin")
        mapKey('<leader>ff', builtin.find_files)
        mapKey('<leader>fg', builtin.live_grep)
        mapKey('<leader>fb', builtin.buffers)
        mapKey('<leader>fh', builtin.help_tags) 
    end,
}
