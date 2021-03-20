local packpath = os.getenv("PACKPATH") or "/tmp/babelfish/nvim/site"
vim.cmd("set packpath=" .. packpath)

if pcall(require, "nvim-treesitter.parsers") then
  local parser_config = require "nvim-treesitter.parsers".get_parser_configs()

  parser_config.markdown = {
    install_info = {
      url = "https://github.com/ikatyang/tree-sitter-markdown",
      files = { "src/parser.c", "src/scanner.cc" },
    }
  }

end
