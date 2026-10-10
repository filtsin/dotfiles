local tab_mapping = function()
    local has_words_before = function()
        local line, col = unpack(vim.api.nvim_win_get_cursor(0))
        return col ~= 0 and vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(col, col):match("%s") == nil
    end

    local cmp = require('cmp')

    return cmp.mapping(function(fallback)
        if cmp.visible() then
            cmp.select_next_item()
        elseif has_words_before() then
            cmp.complete()
        else
            fallback()
        end
    end, { "i", "s" })
end

local shift_tab_mapping = function()
    local cmp = require('cmp')

    return cmp.mapping(function(fallback)
        if cmp.visible() then
            cmp.select_prev_item()
        else
            fallback()
        end
    end, { "i", "s" })
end

local snippet_forward = function()
    local cmp = require('cmp')
    return cmp.mapping(function(fallback)
        if vim.snippet.active({ direction = 1 }) then
            vim.snippet.jump(1)
        else
            fallback()
        end
    end, { 'i', 's' })
end

local snippet_backward = function()
    local cmp = require('cmp')
    return cmp.mapping(function(fallback)
        if vim.snippet.active({ direction = -1 }) then
            vim.snippet.jump(-1)
        else
            fallback()
        end
    end, { 'i', 's'})
end

return {
    {
        'hrsh7th/nvim-cmp',
        event = 'InsertEnter',
        dependencies = {
            'hrsh7th/cmp-buffer',
            'hrsh7th/cmp-path',
            'hrsh7th/cmp-nvim-lsp',
            'onsails/lspkind-nvim',
        },
        opts = function()
            local capabilities = vim.lsp.protocol.make_client_capabilities()
            capabilities = require('cmp_nvim_lsp').default_capabilities(capabilities)

            vim.o.completeopt = 'menuone,noselect'
            local cmp = require('cmp')

            return {
                snippet = {
                    expand = function(args)
                        vim.snippet.expand(args.body)
                    end,
                },
                window = {
                    documentation = cmp.config.window.bordered({
                        winhighlight = "Normal:CmpNormal"
                    }),
                    completion = cmp.config.window.bordered({
                        winhighlight = "Normal:CmpNormal"
                    }),
                },
                sources = {
                    { name = 'nvim_lsp' },
                    { name = 'buffer' },
                    { name = 'path' },
                    { name = 'crates' }
                },
                mapping = {
                    ['<C-Space>'] = cmp.mapping.complete({}),
                    ['<CR>'] = cmp.mapping.confirm(),
                    ['<Tab>'] = tab_mapping(),
                    ['<S-Tab>'] = shift_tab_mapping(),
                    ['<C-e>'] = cmp.mapping.close(),
                    ['<C-l>'] = snippet_forward(),
                    ['<C-h>'] = snippet_backward(),
                },
                formatting = {
                    format = require('lspkind').cmp_format({
                        with_text = true,
                        menu = ({
                            buffer = '[Buffer]',
                            nvim_lsp = '[LSP]',
                            path = '[Path]',
                        })
                    }),
                },
                experimental = {
                    ghost_text = true
                }
            }
        end,
    }
}
