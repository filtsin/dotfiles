return {
    {
        'EdenEast/nightfox.nvim',
        lazy = false,
        priority = 10000,
        opts = {
            palettes = {
                all = {
                    bg1 = '#1d1a17'
                }
            }
        },
        config = function(_, opts)
            require('nightfox').setup(opts);
            vim.cmd('colorscheme carbonfox')
            vim.api.nvim_set_hl(0, 'NormalFloat', { bg = '#303030' })
            vim.api.nvim_set_hl(0, 'CmpNormal', { bg = '#303030' })
        end,
    },
    {
        'stevearc/oil.nvim',
        priority = 999,
        opts = {
            columns = { 'icon', 'size' },
        },
        config = function(_, opts)
            require('oil').setup(opts)
            vim.api.nvim_create_user_command('Exp', function() require('oil').open() end, {})
            vim.keymap.set('n', '<leader>t', function()
                local current_dir = require('oil').get_current_dir()
                vim.cmd('cd ' .. current_dir)
                vim.cmd('terminal')
                vim.cmd('startinsert')
            end)
        end,
    },
    {
        'folke/noice.nvim',
        dependencies = { "MunifTanjim/nui.nvim", "rcarriga/nvim-notify" },
        opts = {
            lsp = {
                override = {
                    ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
                    ["vim.lsp.util.stylize_markdown"] = true,
                    ["cmp.entry.get_documentation"] = true,
                },
                signature = {
                    enabled = false
                },
            },
            routes = {
                {
                    filter = {
                        event = "msg_show",
                        find = "written",
                    },
                    opts = { skip = true },
                },
                {
                    filter = {
                        event = "msg_show",
                        find = "before #",
                    },
                    opts = { skip = true },
                },
                {
                    filter = {
                        event = "msg_show",
                        find = "E37:",
                    },
                    opts = { skip = true },
                },
                {
                    filter = {
                        event = "msg_show",
                        find = "Invalid offset LineCol",
                    },
                    opts = { skip = true },
                },
                {
                    filter = {
                        find = 'Highlight group',
                    },
                    opts = { skip = true },
                },
                {
                    filter = {
                        find = 'No code actions available',
                    },
                    opts = { skip = true },
                },
                {
                    filter = {
                        find = 'no package metadata for file',
                    },
                    opts = { skip = true },
                }
            },
            views = {
                cmdline_popup = {
                    border = {
                    },
                    filter_options = {},
                },
            },
        }
    },
    {
        'nvim-lualine/lualine.nvim',
        dependencies = { 'nvim-tree/nvim-web-devicons', 'folke/noice.nvim', },
        opts = {
            options = { theme = 'tomorrow_night', },
            sections = {
                lualine_b = { 'branch', 'diff',
                    { 'diagnostics', sources = { 'nvim_diagnostic' }, sections = { 'error', 'warn', 'info' } }
                },
                lualine_c = { { 'filename', path = 1 }, 'lsp_progress' },
                lualine_x = {
                    {
                        require('noice').api.status.mode.get,
                        cond = require('noice').api.status.mode.has,
                        color = { fg = '#ff9e64' },
                    },
                    {
                        require("noice").api.status.command.get,
                        cond = require("noice").api.status.command.has,
                        color = { fg = "#ff9e64" },
                    },
                    {
                        require("noice").api.status.search.get,
                        cond = require("noice").api.status.search.has,
                        color = { fg = "#ff9e64" },
                    },
                }
            },
        }
    },
    {
        'alvarosevilla95/luatab.nvim',
        opts = {
            windowCount = function(index)
                return index .. ' '
            end,
            title = function(bufnr)
                local file = vim.fn.bufname(bufnr)
                local buftype = vim.fn.getbufvar(bufnr, '&buftype')
                local filetype = vim.fn.getbufvar(bufnr, '&filetype')

                if buftype == 'help' then
                    return 'help:' .. vim.fn.fnamemodify(file, ':t:r')
                elseif buftype == 'quickfix' then
                    return 'quickfix'
                elseif filetype == 'TelescopePrompt' then
                    return 'Telescope'
                elseif buftype == 'terminal' then
                    local _, mtch = string.match(file, "term:(.*):(%a+)")
                    return mtch ~= nil and mtch or vim.fn.fnamemodify(vim.env.SHELL, ':t')
                elseif file == '' then
                    return '[Empty]'
                else
                    return vim.fn.fnamemodify(file, ':p:h:t') .. '/' .. vim.fn.fnamemodify(file, ':t')
                end
            end
        }
    },
}
