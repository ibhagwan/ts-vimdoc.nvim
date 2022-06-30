local packpath = os.getenv("PACKPATH") or "/tmp/babelfish/nvim/site"
vim.cmd("set packpath=" .. packpath)

require'nvim-treesitter.configs'.setup {
  -- ensure_installed = {
  --     "markdown",
  --     "markdown_inline",
  -- }
}
