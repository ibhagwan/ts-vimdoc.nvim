-- add temp path from scripts/docgen.sh in case this is running locally
local tempdir = vim.trim(vim.fn.system('sh -c "dirname $(mktemp -u)"'))
local packpath = os.getenv("PACKPATH") or tempdir .. "/ts-vimdoc.nvim.tmp/nvim/site"
vim.cmd("set packpath=" .. packpath)

require'nvim-treesitter.configs'.setup {
  -- not needed since we're using `:TSUpdateSync`
  -- ensure_installed = {
  --     "markdown",
  --     "markdown_inline",
  -- }
}
