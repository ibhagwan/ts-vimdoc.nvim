local get_node_text = require('vim.treesitter.query').get_node_text

local metadata = {
  project_name = "lspconfig",
}

local tokens = {
  heading = "atx_heading",
  loose_list = "loose_list",
  tight_list = "tight_list",
  list_item = "list_item",
  fenced_code_block = "fenced_code_block",
  paragraph = "paragraph"
}

local style_elements = {
  header_break = string.rep("=", 78),
}

local header_alias = {
}

local function indent(text_table, indent_level)
  for idx, entry in ipairs(text_table) do
    text_table[idx] = string.rep(" ", indent_level) .. entry
  end
  return text_table
end

local header_count = 1
local function recursive_parser(parent_node, content, parsed_content)
  for node in parent_node:iter_children() do

    if node:type() == tokens.fenced_code_block then
      local codeblock_content = recursive_parser(node, content, {} )
      codeblock_content = table.concat(indent(codeblock_content, 4), "")
      vim.list_extend(parsed_content, {"\n>", codeblock_content, "<\n\n" })

    elseif node:type() == tokens.heading then
      local text = get_node_text(node, content)
      text = string.gsub(text, "#+%s", "")
      local left = string.format("%d. %s", header_count, text)
      local right = string.lower(string.gsub(text, "%s", "-"))
      right = string.format("*%s-%s*", metadata.project_name, right)
      local padding = string.rep(" ", 78 - #left - #right)
      text = string.format("%s%s%s", left, padding, right)
      vim.list_extend(parsed_content, {style_elements.header_break, text, "\n"})
      header_count = header_count + 1

    elseif node:type() == tokens.paragraph then
      local text = get_node_text(node, content)
      vim.list_extend(parsed_content, {text})

    elseif node:type() == tokens.list_item then
      local text = get_node_text(node, content)
      vim.list_extend(parsed_content, {text})

    elseif node:child_count() > 0 then
      parsed_content = vim.list_extend(parsed_content, recursive_parser(node, content, {}))

    else
      local text = get_node_text(node, content)
      vim.list_extend(parsed_content, {text})
    end
  end
  return parsed_content
end

local function parse_markdown(parser, contents)
  local tstree = parser:parse()[1]
  local parent_node = tstree:root()

  local formatted_file = recursive_parser(parent_node, contents, {})
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
