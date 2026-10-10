return {
    {
        'nvim-treesitter/nvim-treesitter',
        opts = { ensure_installed = { 'go' } },
    },

    {
        'neovim/nvim-lspconfig',
        dependencies = {
            'mason-org/mason-lspconfig.nvim',
            opts = { ensure_installed = { 'gopls' } },
        },
        opts = {
            servers = {
                gopls = {
                    settings = {
                        gopls = {
                            gofumpt = true,
                            codelenses = {
                                gc_details = false,
                                generate = true,
                                regenerate_cgo = true,
                                run_govulncheck = true,
                                test = true,
                                tidy = true,
                                upgrade_dependency = true,
                                vendor = true,
                            },
                            hints = {
                                assignVariableTypes = true,
                                compositeLiteralFields = true,
                                compositeLiteralTypes = true,
                                constantValues = true,
                                functionTypeParameters = true,
                                parameterNames = true,
                                rangeVariableTypes = true,
                            },
                            analyses = {
                                nilness = true,
                                unusedparams = true,
                                unusedwrite = true,
                                useany = true,
                            },
                            usePlaceholders = true,
                            completeUnimported = true,
                            staticcheck = true,
                            directoryFilters = { "-.git", },
                            semanticTokens = true,
                        },
                    },
                    on_attach = function(_, bufnr)
                        vim.keymap.set('n', '<leader>z', function()
                            vim.lsp.buf.format()
                            vim.lsp.buf.code_action({
                                context = { only = { "source.organizeImports" }, diagnostics = {} },
                                apply = true

                            })
                        end, { desc = 'Format current buffer and organize imports', buffer = bufnr })
                    end
                },
            }
        }
    }
}
