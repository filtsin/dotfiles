return {
    {
        'nvim-treesitter/nvim-treesitter',
        opts = { ensure_installed = { 'rust' } },
    },
    {
        'neovim/nvim-lspconfig',
        dependencies = {
            'mason-org/mason-lspconfig.nvim',
            opts = { ensure_installed = { 'rust_analyzer' } },
        },
        opts = {
            servers = {
                rust_analyzer = {
                    settings = {
                        ['rust-analyzer'] = {
                            assist = {
                                importGranularity = 'module',
                                importPrefix = 'by_self'
                            },
                            inlayHints = {
                                parameterHints = false,
                            },
                            check = {
                                command = 'clippy'
                            },
                            cargo = {
                                allFeatures = true,
                            },
                            rustfmt = {
                                extraArgs = { "+nightly" }
                            },
                            lens = {
                                enable = false,
                            },
                        }
                    },
                    on_attach = function(_, _)
                        vim.api.nvim_command [[
                            autocmd BufWritePre *.rs lua vim.lsp.buf.format()
                        ]]
                    end,
                }
            }
        },
    },
    {
        'saecki/crates.nvim',
        event = 'BufRead Cargo.toml',
        dependencies = { 'nvim-lua/plenary.nvim' },
        opts = {
            lsp = {
                enabled = true,
                actions = true,
                completion = true,
                hover = true,
            },
        },
        keys = {
            { '<leader>z', function() require('crates').toggle() end },
            { '<leader>u', function() require('crates').upgrade_crate() end },
            { '<leader>U', function() require('crates').upgrade_all_crates() end },
        }
    },
}
