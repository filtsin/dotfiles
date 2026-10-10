return {
    {
        'folke/flash.nvim',
        opts = {
            modes = {
                char = {
                    jump_labels = true
                }
            }
        },
        keys = {
            { 's',     function() require('flash').jump() end },
            { 'S',     function() require('flash').treesitter() end },
            { 'f',     function() require('flash').remote() end },
            { '<c-s>', function() require('flash').toggle() end,    mode = { 'c' } }
        }
    },
    {
        'lewis6991/gitsigns.nvim',
        event = 'VeryLazy',
        opts = {},
    },
    {
        'tpope/vim-fugitive',
        cmd = 'Git',
    },
    {
        'numToStr/Comment.nvim',
        keys = {
            { 'gc', function() require('Comment.api').toggle() end, mode = { 'v' } }
        },
        opts = {},
    },
    {
        'nvim-pack/nvim-spectre',
        cmd = "Spectre",
        opts = {},
    },
    {
        'danymat/neogen',
        cmd = 'Neogen',
        keys = {
            { '<leader>ng', function() require('neogen').generate() end, desc = 'Generate documentation' }
        },
        opts = {}
    },
    {
        'nmac427/guess-indent.nvim',
        opts = {},
    }
}
