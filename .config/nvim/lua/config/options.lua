local opt = vim.opt

-- tab/indent
opt.tabstop = 4
opt.shiftwidth = 4
opt.softtabstop = 4
opt.expandtab = true
opt.smartindent = true
opt.wrap = false

-- Search
opt.incsearch = true
opt.ignorecase = true
opt.smartcase = true

-- visual 
opt.number = true
opt.relativenumber = true
opt.termguicolors = true
opt.signcolumn = "yes"
opt.foldcolumn = "0"
opt.foldmethod = "indent"
opt.foldlevel = 99
opt.foldlevelstart = 99
opt.foldenable = true
opt.completeopt = { "menu", "menuone", "noselect", "popup" }

-- etc
opt.encoding = "UTF-8"
opt.clipboard = "unnamedplus"
opt.cmdheight = 1
opt.scrolloff = 10
opt.mouse:append("a")
