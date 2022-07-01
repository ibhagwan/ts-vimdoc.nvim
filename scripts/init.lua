-- add temp path from scripts/docgen.sh in case this is running locally
local packpath = os.getenv("PACKPATH") or "/tmp/ts-vimdoc.nvim/nvim/site"
vim.cmd("set packpath=" .. packpath)

require'nvim-treesitter.configs'.setup {
  -- not needed since we're using `:TSUpdateSync`
  -- ensure_installed = {
  --     "markdown",
  --     "markdown_inline",
  -- }
}
