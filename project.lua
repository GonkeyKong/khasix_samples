-- Project config for neovim

-- local sample = "sample_platform.odin"
local sample = "sample_basic_renderer.odin"

local build_samples = [[.\build_samples.bat ]]
local shaders_compile_d3d11 = [[.\khasix\basic_renderer\shaders_compile_d3d11.bat]]

-- Build functions
local function compile_code()
  vim.cmd("wa")
  vim.opt.makeprg = build_samples .. sample
  vim.cmd("Make")
end

local function compile_shaders()
  vim.cmd("wa")
  vim.opt.makeprg = shaders_compile_d3d11
  vim.cmd("Make")
end

-- Keybindings
vim.keymap.set('n', '<leader>do', '<cmd>!start raddbg --project:./khasix_samples.raddbg_project<cr>')
vim.keymap.set('n', '<f8>', compile_code)
vim.keymap.set('n', '<f9>', compile_shaders)
vim.keymap.set('n', '<f10>', '<cmd>!odin run test.odin -file<cr>')

-- Ignores
vim.opt.wildignore:append({
  "bin/**",
  "**shaders_bin**/**",
})
