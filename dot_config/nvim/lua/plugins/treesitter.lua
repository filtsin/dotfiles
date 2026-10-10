return {
    {
        'nvim-treesitter/nvim-treesitter',
        dependencies = { 'nvim-treesitter/nvim-treesitter-context' },
        build = ':TSUpdate',
        lazy = vim.fn.argc(-1) == 0, -- load treesitter early when opening a file from the cmdline
        event = { 'VeryLazy' },
        opts = {
            ensure_installed = {
                'regex',
                'vim',
                'bash',
                'markdown',
                'markdown_inline',
                'cpp',
                'go',
                'python',
            },
            highlight = {
                enable = true
            },
            autotag = {
                enable = true
            },
            matchup = {
                enable = true
            },
            -- TODO nvim 0.12 https://pawelgrzybek.com/nvim-incremental-selection/
            incremental_selection = {
                enable = true,
                keymaps = {
                    init_selection = "<A-o>",
                    node_incremental = "]v",
                    node_decremental = "[v",
                },
            },

        },
        opts_extend = { 'ensure_installed' },
        config = function(_, opts)
            require('nvim-treesitter')
                .install(
                    {
                        'regex',
                        'vim',
                        'bash',
                        'markdown',
                        'markdown_inline',
                        'cpp',
                        'go',
                        'python',
                        'rust',
                        'toml'
                    }
                )
        end,
    }
}
