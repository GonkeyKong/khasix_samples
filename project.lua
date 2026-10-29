-- Project config for neovim
vim.opt.makeprg = [[ .\build_samples.bat sample_basic_renderer.odin ]]
vim.keymap.set('n', '<leader>do', '<cmd>!start raddbg --project:./khasix_samples.raddbg_project<cr>')
vim.keymap.set('n', '<f9>', '<cmd>!odin run test.odin -file<cr>')
