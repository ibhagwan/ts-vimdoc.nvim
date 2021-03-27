local get_node_text = require('vim.treesitter.query').get_node_text

local tokens = {
  heading = "atx_heading",
  loose_list = "loose_list",
  tight_list = "tight_list",
  list_item = "list_item",
  fenced_code_block = "fenced_code_block",
  code_fence_content = "code_fence_content",
  paragraph = "paragraph",
  soft_line_break = "soft_line_break",
  link = "link"
}

local style_elements = {
  header_break = string.rep("=", 78),
}

local converter = {}
local docgen = {}

converter.fenced_code_block = function(node, content, parsed_content, metadata)
  for child_node in node:iter_children() do
    if child_node:type() == tokens.code_fence_content then
      node = child_node
    end
  end
  local codeblock_content = docgen.recursive_parser(node, content, {}, metadata)
  codeblock_content = table.concat(docgen.indent(codeblock_content, 4), "")
  vim.list_extend(parsed_content, {"\n>", codeblock_content, "<\n\n" })
  return parsed_content
end

local header_count = 1
converter.heading = function(node, content, parsed_content, metadata)
  local text = get_node_text(node, content)
  text = string.gsub(text, "#+%s", "")
  local left
  local right
  if not metadata.header_aliases[text] then
    left = string.format("%d. %s", header_count, text)
    right = string.lower(string.gsub(text, "%s", "-"))
    right = string.format("*%s-%s*", metadata.project_name, right)
  else
    left = string.format("%d. %s", header_count, metadata.header_aliases[text][1])
    right = string.lower(string.gsub(metadata.header_aliases[text][2], "%s", "-"))
    right = string.format("*%s-%s*", metadata.project_name, right)
  end
  local padding = string.rep(" ", 78 - #left - #right)
  text = string.format("%s%s%s", left, padding, right)
  vim.list_extend(parsed_content, {style_elements.header_break, text, "\n"})
  header_count = header_count + 1
  return parsed_content
end

converter.paragraph = function(parent_node, content, parsed_content, _)
  local current_line = ""
  for node in parent_node:iter_children() do
    local text = get_node_text(node, content)
    if node:type() == tokens.link then
      current_line =  current_line .. " " .. text
    else
      for word in string.gmatch(text, "([^%s]+)") do
        if string.match(word, "[.]") and #word == 1 then
          current_line =  current_line .. word
        elseif (#current_line + #word) > 78 then
          table.insert(parsed_content, current_line)
          current_line =  word
        elseif #current_line == 0 then
          current_line = word
        else
          current_line = current_line .. " " .. word
        end
      end
    end
  end
  table.insert(parsed_content, current_line)
  return parsed_content
end

converter.generic = function(node, content, parsed_content, _)
  local text = get_node_text(node, content)
  vim.list_extend(parsed_content, {text})
  return parsed_content
end

converter.methods = {
  [tokens.fenced_code_block] = converter.fenced_code_block,
  [tokens.heading] = converter.heading,
  [tokens.paragraph] = converter.paragraph,
  [tokens.list_item] = converter.generic,
}

docgen.indent = function(text_table, indent_level)
  for idx, entry in ipairs(text_table) do
    text_table[idx] = string.rep(" ", indent_level) .. entry
  end
  return text_table
end

docgen.recursive_parser = function(parent_node, content, parsed_content, metadata)
  for node in parent_node:iter_children() do

    if converter.methods[node:type()] then
      parsed_content = converter.methods[node:type()](node, content, parsed_content, metadata)

    elseif node:child_count() > 0 then
      parsed_content = vim.list_extend(parsed_content, docgen.recursive_parser(node, content, {}, metadata))

    else
      local text = get_node_text(node, content)
      vim.list_extend(parsed_content, {text})
    end

  end
  return parsed_content
end

docgen.parse_markdown = function (parser, contents, metadata)
  local tstree = parser:parse()[1]
  local parent_node = tstree:root()

  local formatted_file = docgen.recursive_parser(parent_node, contents, {}, metadata)
  table.insert(formatted_file, "vim:tw=78:ts=8:ft=help:norl:")

  local final_text = table.concat(formatted_file, "\n")
  return final_text
end

docgen.generate_readme = function(metadata)
  local fp = assert(io.open(metadata.input_file))
  local contents = fp:read("*all")
  fp:close()

  local parser = vim.treesitter.get_string_parser(contents, "markdown")
  local readme_data = docgen.parse_markdown(parser, contents, metadata)

  local writer = io.open(metadata.output_file, "w")
  writer:write(readme_data)
  writer:close()
end

return docgen
