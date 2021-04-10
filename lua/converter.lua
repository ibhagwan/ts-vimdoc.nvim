local tokens = require('tokens').tokens
local formatting = require('formatting')
local get_node_text = require('vim.treesitter.query').get_node_text

local converter = {}

converter.fenced_code_block = function(node, content, parsed_content, metadata)
  for child_node in node:iter_children() do
    if child_node:type() == tokens.code_fence_content then
      node = child_node
    end
  end
  local codeblock_content = converter.recursive_parser(node, content, {}, metadata)
  codeblock_content = table.concat(formatting.indent(codeblock_content, 4), "")
  vim.list_extend(parsed_content, {"\n>", codeblock_content, "<\n\n" })
  return parsed_content
end

local header_count = 1
converter.heading = function(node, content, parsed_content, metadata)
  local text = get_node_text(node, content)
  text = string.gsub(text, "#+%s", "")
  local left
  local right
  if metadata.header_aliases and metadata.header_aliases[text] then
    left = string.format("%d. %s", header_count, metadata.header_aliases[text][1])
    right = string.lower(string.gsub(metadata.header_aliases[text][2], "%s", "-"))
    right = string.format("*%s-%s*", metadata.project_name, right)
  else
    left = string.format("%d. %s", header_count, text)
    right = string.lower(string.gsub(text, "%s", "-"))
    right = string.format("*%s-%s*", metadata.project_name, right)
  end
  local padding = string.rep(" ", 78 - #left - #right)
  text = string.format("%s%s%s", left, padding, right)
  vim.list_extend(parsed_content, {formatting.style_elements.header_break, text, "\n"})
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

converter.recursive_parser = function(parent_node, content, parsed_content, metadata)
  for node in parent_node:iter_children() do

    if converter.methods[node:type()] then
      parsed_content = converter.methods[node:type()](node, content, parsed_content, metadata)

    elseif node:child_count() > 0 then
      parsed_content = vim.list_extend(parsed_content, converter.recursive_parser(node, content, {}, metadata))

    else
      local text = get_node_text(node, content)
      vim.list_extend(parsed_content, {text})
    end

  end
  return parsed_content
end

return converter
