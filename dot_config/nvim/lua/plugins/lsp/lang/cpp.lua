return {
    {
        'nvim-treesitter/nvim-treesitter',
        opts = { ensure_installed = { 'cpp' } },
    },

    {
        'neovim/nvim-lspconfig',
        dependencies = {
            'mason-org/mason-lspconfig.nvim',
            -- opts = { ensure_installed = { 'clangd' } },
        },
        opts = {
            servers = {
                clangd = {
                    cmd = function(dispatchers, config)
                        local root = config.root_dir
                        local cmd = {
                            'clangd',
                            '--background-index',
                            '--clang-tidy',
                            '--experimental-modules-support',
                        }

                        return vim.lsp.rpc.start(cmd, dispatchers)
                    end,
                    keys = {
                        { '<space>t', ':LspClangdSwitchSourceHeader<cr>', { desc = 'Switch Source/Header' } },
                    },
                    init_options = {
                        fallbackFlags = { '-std=c++23', '-stdlib=libc++' },
                        usePlaceholders = true,
                        completeUnimported = true,
                        clangdFileStatus = true
                    },
                    root_markers = {
                        '.clangd',
                        'compile_commands.json',
                        '.clang-format',
                        'clang-format',
                    },
                }
            }
        },
    },
}
