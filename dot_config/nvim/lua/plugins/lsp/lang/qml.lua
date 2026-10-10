return {
    {
        'neovim/nvim-lspconfig',
        dependencies = {
            'mason-org/mason-lspconfig.nvim',
            opts = { ensure_installed = { 'qmlls' } },
        },
        opts = {
            servers = {
                qmlls = {
                    cmd = {
                        'qmlls',
                        '-E',
                        '-I', '/usr/lib/qt6/qml',
                        '-I', '/etc/xdg/quickshell/noctalia-shell/',
                        '-I', '/etc/xdg/quickshell/noctalia-shell/Modules'
                    }
                }
            }
        },
    },
}
