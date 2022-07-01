local converter = require('converter')
local M = {}

M.parse_markdown = function (parser, contents)
  local tstree = parser:parse()[1]
  local parent_node = tstree:root()

  local formatted_file = converter.recursive_parser(parent_node, contents)
  table.insert(formatted_file, "\nvim:tw=78:ts=8:ft=help:norl:")

  local final_text = table.concat(formatted_file, "\n")
  return final_text
end

M.docgen = function(metadata)
  local fp = assert(io.open(metadata.input_file))
  local contents = fp:read("*all")
  fp:close()

  converter.handlers = vim.tbl_extend('force', converter.handlers, metadata.handlers or {})
  converter.metadata = vim.tbl_extend('force', converter.metadata or {}, metadata)

  local parser = vim.treesitter.get_string_parser(contents, "markdown")
  local readme_data = M.parse_markdown(parser, contents)

  local writer = io.open(metadata.output_file, "w")
  writer:write(readme_data)
  writer:close()
end

return M
