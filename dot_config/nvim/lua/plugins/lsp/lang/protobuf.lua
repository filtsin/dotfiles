return {
    {
        'neovim/nvim-lspconfig',
        dependencies = {
            'mason-org/mason-lspconfig.nvim',
            opts = { ensure_installed = { 'protols' } },
        },
        opts = {
            servers = {
                protols = {}
            }
        }
    }
}
