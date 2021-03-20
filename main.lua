local get_node_text = require('vim.treesitter.query').get_node_text

local metadata = {
  project_name = "nvim-lspconfig",
}

local tokens = {
  heading = "atx_heading",
  loose_list = "loose_list",
  tight_list = "tight_list",
  fenced_code_block = "fenced_code_block",
  paragraph = "paragraph"
}

local style_elements = {
  header_break = string.rep("=", 78),
}

local function recursive_parser(parent_node, content, concatenated_content)
  for node in parent_node:iter_children() do
    if node:child_count() > 0 then
      concatenated_content = recursive_parser(node, content, concatenated_content)
    else
      local text = get_node_text(node, content)
      concatenated_content = concatenated_content .. text
    end
  end
  return concatenated_content
end

local function parse_markdown(parser, contents)
  local tstree = parser:parse()[1]
  local formatted_file = {}
  local parent_node = tstree:root()

  local header_count = 1
  for node in parent_node:iter_children() do
    local node_type = node:type()
    if node_type == tokens.heading then
      table.insert(formatted_file, style_elements.header_break)
      local text = get_node_text(node, contents)
      text = string.gsub(text, "#*[ ]", "")
      local left = string.format("%d. %s", header_count, text)
      local right = string.format("*%s-%s*", metadata.project_name, string.lower(text))
      local padding = string.rep(" ", 78 - #left - #right)
      text = string.format("%s%s%s", left, padding, right)
      header_count = header_count + 1
      table.insert(formatted_file, text)
      table.insert(formatted_file, " ")
    else
      local text = get_node_text(node, contents)
      -- local new_text = recursive_parser(node, contents, "")
      table.insert(formatted_file, text)
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
