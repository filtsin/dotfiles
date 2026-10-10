return {
    {
        'nvim-treesitter/nvim-treesitter',
        opts = { ensure_installed = { 'python' } },
    },

    {
        'neovim/nvim-lspconfig',
        dependencies = {
            'mason-org/mason-lspconfig.nvim',
            opts = { ensure_installed = { 'pyright' } },
        },
        opts = {
            servers = {
                pyright = {
                }
            }
        }
    },
}
