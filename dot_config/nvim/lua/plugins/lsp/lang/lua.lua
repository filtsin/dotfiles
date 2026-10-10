return {
    {
        'nvim-treesitter/nvim-treesitter',
        opts = { ensure_installed = { 'lua' } },
    },

    {
        'neovim/nvim-lspconfig',
        dependencies = {
            'mason-org/mason-lspconfig.nvim',
            opts = { ensure_installed = { 'lua_ls' } },
        },
        opts = {
            servers = {
                lua_ls = {
                    settings = {
                        Lua = {
                            runtime = {
                                version = 'LuaJIT'
                            },
                            workspace = {
                                checkThirdParty = false,
                                library = {
                                    vim.env.VIMRUNTIME
                                }
                            },
                            diagnostics = {
                                -- Get the language server to recognize the 'vim', 'use' global
                                globals = { 'vim', 'use' },
                            },
                            -- Do not send telemetry data containing a randomized but unique identifier
                            telemetry = {
                                enable = false,
                            },
                            codeLens = true,
                        },
                    }
                }
            }
        }
    },
    {
        'folke/neodev.nvim',
        event = 'BufReadPre *.lua',
        opts = {},
    }
}
