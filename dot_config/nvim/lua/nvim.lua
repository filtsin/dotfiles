local opt = vim.opt
local cmd = vim.cmd

cmd [[
    set mouse=
    filetype indent plugin on
    syntax enable
]]

cmd [[highlight ColorColumn ctermbg=0]]

-- Hack for ranger on startup
vim.g.ranger_replace_netrw = 1
vim.g.ranger_map_keys = 0

opt.shiftwidth = 4
opt.softtabstop = 4
opt.tabstop = 4
opt.expandtab = true
opt.autoindent = true
opt.timeoutlen = 300
opt.encoding = 'utf-8'
opt.showmode = false
opt.hidden = true
opt.wrap = false
opt.joinspaces = false
opt.signcolumn = 'yes'
opt.undofile = true
opt.undodir = '/home/filtsin/.vimdid'
opt.foldenable = false
opt.ttyfast = true
opt.synmaxcol = 500
opt.laststatus = 2
opt.relativenumber = true
opt.number = true
opt.colorcolumn = '100'
opt.showcmd = true
opt.autoread = true
opt.clipboard = 'unnamedplus'
opt.termguicolors = true
opt.swapfile = false
opt.mouse = nil

vim.g.mapleader = '\\'

vim.keymap.set('', '<up>', '')
vim.keymap.set('', '<down>', '')
vim.keymap.set('', '<left>', '')
vim.keymap.set('', '<right>', '')

vim.keymap.set('i', 'jj', '<Esc>')
vim.keymap.set('n', '<leader>w', ':w<CR>')
vim.keymap.set('n', '<leader>c', ':tablose<CR>')
