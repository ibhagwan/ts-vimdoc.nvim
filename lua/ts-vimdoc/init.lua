local utils = require("ts-vimdoc.utils")
local parser = require('ts-vimdoc.parser')
local M = {}

M.docgen = function(metadata)
  metadata = metadata or {}
  vim.validate ({
    input_file = { metadata.input_file, 'string' },
    output_file = { metadata.output_file, 'string' },
    project_name = { metadata.project_name, 'string' },
  })

  local fp = assert(io.open(metadata.input_file))
  local content = fp:read("*all")
  fp:close()

  local vimdoc = parser:new({
    content = content,
    metadata = metadata
  }):parse()

  -- print("new contents:", vimdoc)

  local writer = io.open(metadata.output_file, "w")
  writer:write(vimdoc)
  writer:close()
end

return M
