local ts_utils = require 'nvim-treesitter.ts_utils'

local header_break = "=============================================================================="
local get_node_text = require('vim.treesitter.query').get_node_text

local function parse_markdown(parser, contents)
  local tstree = parser:parse()[1]
  local formatted_file = {}
  local parent_node = tstree:root()

  for node in parent_node:iter_children() do
    local node_type = node:type()
    if node_type == "atx_heading" then
      table.insert(formatted_file, header_break)
      local text = get_node_text(node, contents)
      -- local text = get_node_text(node, contents)[1]
      text = string.gsub(text, "#*", "")
      table.insert(formatted_file, text)
      table.insert(formatted_file, " ")
    else
      for child_node in  node:iter_children() do
        local text = get_node_text(child_node, contents)
        table.insert(formatted_file, text)
      end
    end

  end

  table.insert(formatted_file, "vim:tw=78:ts=8:ft=help:norl:")
  local final_text = table.concat(formatted_file, "\n")

  return final_text
end

local function generate_readme()
  local fp = assert(io.open("tests/README.md"))
  local contents = fp:read("*all")
  fp:close()
  local parser = vim.treesitter.get_string_parser(contents, "markdown")

  local readme_data = parse_markdown(parser, contents)

  local writer = io.open("help.txt", "w")
  writer:write(readme_data)
  writer:close()
end

generate_readme()
