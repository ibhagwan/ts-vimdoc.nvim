local parser = require("ts-vimdoc.parser")
local M = {}

M.docgen = function(metadata)
  metadata = metadata or {}
  metadata.version = metadata.version and string.format("%s", metadata.version) or ""
  metadata.table_of_contents_lvl_min = tonumber(metadata.table_of_contents_lvl_min) or 2
  metadata.table_of_contents_lvl_max = tonumber(metadata.table_of_contents_lvl_max) or 5
  vim.validate({
    input_file = { metadata.input_file, "string" },
    output_file = { metadata.output_file, "string" },
    project_name = { metadata.project_name, "string" },
  })

  local fp = assert(io.open(metadata.input_file))
  local content = fp:read("*all")
  fp:close()

  local vimdoc = parser:new({
    content = content,
    metadata = metadata
  }):parse()

  -- print("new contents:", vimdoc)

  local writer = assert(io.open(metadata.output_file, "w"))
  writer:write(vimdoc)
  writer:close()
end

return M
