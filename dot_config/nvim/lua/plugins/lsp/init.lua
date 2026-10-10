return {
    {
        'neovim/nvim-lspconfig',
        event = 'VeryLazy',
        dependencies = {
        },
        opts = {
            diagnostics = {
                underline = true,
                update_in_insert = false,
                virtual_text = false,
                severity_sort = true,
                signs = { -- false to disable
                    text = {
                        [vim.diagnostic.severity.ERROR] = ' ',
                        [vim.diagnostic.severity.WARN] = ' ',
                        [vim.diagnostic.severity.HINT] = ' ',
                        [vim.diagnostic.severity.INFO] = ' ',
                    },
                },
                inlay_hints = {
                    enable = true,
                },
                codelens = {
                    enable = true,
                }
            },
        },
        config = function(_, opts)
            vim.api.nvim_create_autocmd('LspAttach', {
                callback = function(args)
                    require('plugins.lsp.keymaps').on_attach(args.buf)
                end
            })

            if type(opts.diagnostics.signs) ~= 'boolean' then
                for severity, icon in pairs(opts.diagnostics.signs.text) do
                    local name = vim.diagnostic.severity[severity]:lower():gsub('^%l', string.upper)
                    name = 'DiagnosticSign' .. name
                    vim.fn.sign_define(name, { text = icon, texthl = name, numhl = "" })
                end
            end

            if type(opts.diagnostics.virtual_text) == 'table' and opts.diagnostics.virtual_text.prefix == 'icons' then
                opts.diagnostics.virtual_text.prefix = function(diagnostic)
                    local icons = opts.diagnostics.signs.text
                    for d, icon in pairs(icons) do
                        if diagnostic.severity == d then
                            return icon
                        end
                    end
                end
            end

            vim.diagnostic.config(vim.deepcopy(opts.diagnostics))

            local function setup(server, server_opts)
                -- local server_opts = vim.tbl_deep_extend('force', {}, opts.servers[server] or {})
                if server_opts.enabled == false then
                    return
                end

                local old_attach_cb = server_opts.on_attach
                local default_attach_cb = vim.lsp.config[server].on_attach


                server_opts.on_attach = function(client, buf)
                    local inlayHintEnabled = server_opts._inlayHints
                    if inlayHintEnabled == nil then inlayHintEnabled = true end

                    local codelens = server_opts._codelens
                    if codelens == nil then codelens = true end

                    if inlayHintEnabled and client:supports_method('textDocument/inlayHint') then
                        vim.lsp.inlay_hint.enable(true, { bufnr = buf })
                    end

                    if codelens and client:supports_method('textDocument/codeLens') then
                        vim.lsp.codelens.enable(true)
                        vim.api.nvim_create_autocmd({ 'BufEnter', 'CursorHold', 'InsertLeave' }, {
                            buffer = buf,
                            once = true,
                            callback = function() vim.lsp.codelens.enable(true) end,
                        })
                    end

                    if old_attach_cb ~= nil then
                        old_attach_cb(client, buf)
                    end

                    if default_attach_cb ~= nil then
                        default_attach_cb(client, buf)
                    end
                end

                vim.lsp.config(server, server_opts)
                vim.lsp.enable(server)
            end

            for server, server_opts in pairs(opts.servers) do
                setup(server, server_opts)
            end
        end,
    },

    {
        'mason-org/mason-lspconfig.nvim',
        dependencies = {
            { 'mason-org/mason.nvim', opts = {} }
        },
        opts = {
            automatic_enable = false,
            ensure_installed = {}
        },
        opts_extend = { 'ensure_installed' }
    },

    {
        'neovim/nvim-lspconfig',
        dependencies = {
            'mason-org/mason-lspconfig.nvim',
        },
        opts = {},
    },

    {
        'nvimdev/lspsaga.nvim',
        event = 'LspAttach',
        opts = {
            outline = {
                win_position = "left",
                win_width = 40,
            },
            diagnostic = {
                on_insert = false
            },
            lightbulb = {
                enable = false
            },
        }
    },

    {
        "rachartier/tiny-inline-diagnostic.nvim",
        event = "VeryLazy",
        priority = 1000,
        config = function()
            require("tiny-inline-diagnostic").setup({
                preset = "simple",
            })
        end,
    },

    { import = 'plugins.lsp.lang' }
}
