local install_path = '/tmp/babelfish/site/pack/packer/opt/packer.nvim'

if vim.fn.empty(vim.fn.glob(install_path)) > 0 then
  vim.fn.execute('!git clone https://github.com/wbthomason/packer.nvim ' .. install_path)
end

-- Only required if you have packer in your `opt` pack
vim.cmd [[packadd packer.nvim]]
vim.api.nvim_exec([[
  augroup Packer
    autocmd!
    autocmd BufWritePost plugins.lua PackerCompile
  augroup end
]], false)

vim.cmd[[set packpath=/tmp/babelfish/site]]

local use = require('packer').use
require('packer').startup(
  {
    function()
  use { 'wbthomason/packer.nvim', opt = true }
  use { 'nvim-treesitter/nvim-treesitter', run = ':TSUpdate' }
  end,
  config = {package_root = "/tmp/babelfish/site/pack"},
}
)
if pcall(require, "nvim-treesitter.parsers") then
  local parser_config = require "nvim-treesitter.parsers".get_parser_configs()

  parser_config.markdown = {
    install_info = {
      url = "https://github.com/ikatyang/tree-sitter-markdown",
      files = { "src/parser.c", "src/scanner.cc" },
    }
  }

end
