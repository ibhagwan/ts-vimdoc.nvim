-- add temp path from scripts/docgen.sh in case this is running locally
local tempdir = vim.trim(vim.fn.system('sh -c "dirname $(mktemp -u)"'))
local packpath = os.getenv("PACKPATH") or tempdir .. "/ts-vimdoc.nvim.tmp/nvim/site"
vim.cmd("set packpath=" .. packpath)

require "nvim-treesitter".setup {}
require "nvim-treesitter".install {
  "markdown",
  "markdown_inline",
}
