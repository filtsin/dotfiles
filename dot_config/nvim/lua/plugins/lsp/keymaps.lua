local M = {}

M._keys = nil

function M.get()
    if M._keys then
        return M._keys
    end

    M._keys = {
        { '<leader>z', vim.lsp.buf.format,     { desc = 'Format current buffer' } },
        { '<space>a', '<cmd>Lspsaga code_action<CR>',
            -- function()
            --     vim.lsp.buf.code_action({ apply = false })
            -- end,
            { desc = 'Code action' }
        },
        { '<leader>rn', vim.lsp.buf.rename, { desc = 'Rename' } },
        { '<leader>x',  vim.lsp.buf.hover,  { desc = 'Hover symbol' } },
        { '<leader>o', '<cmd>Lspsaga outline<CR>', { desc = 'LSP outline' } },
        { '<leader>n',
            function()
                vim.diagnostic.jump({ count = 1, severity = { vim.diagnostic.severity.ERROR, vim.diagnostic.severity.WARN } })
            end,
            { desc = 'Go to next diagnostic' }
        },
    }

    return M._keys
end

function M.on_attach(buffer)
    local keys = vim.tbl_extend('force', {}, M.get())
    local clients = vim.lsp.get_clients({ bufnr = buffer })
    local lsp_config = require('lazy.core.config').spec.plugins['nvim-lspconfig']
    local opts = require('lazy.core.plugin').values(lsp_config, 'opts', false)

    for _, client in ipairs(clients) do
        local maps = opts.servers[client.name] and opts.servers[client.name].keys or {}
        vim.list_extend(keys, maps)
    end

    for _, key in ipairs(keys) do
        if #key ~= 3 then
            vim.notify("Key binding is not valid entry: " .. vim.inspect(key), vim.log.levels.ERROR)
            return
        end
        if type(key[2]) ~= 'function' and type(key[2]) ~= 'string' then
            vim.notify('Key binding ' .. key[1] .. ' is not a valid function', vim.log.levels.ERROR)
            return
        end
        local key_opts = key[3] or {}
        key_opts.buffer = buffer
        vim.keymap.set(key.mode or 'n', key[1], key[2], key_opts)
    end
end

return M
