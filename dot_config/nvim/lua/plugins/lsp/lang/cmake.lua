return {
    {
        'nvim-treesitter/nvim-treesitter',
        opts = { ensure_installed = { 'cmake' } },
    },

    {
        'neovim/nvim-lspconfig',
        dependencies = {
            'mason-org/mason-lspconfig.nvim',
            opts = { ensure_installed = { 'neocmake' } },
        },
        opts = {
            servers = {
                neocmake = {
                }
            }
        },
    },
}
