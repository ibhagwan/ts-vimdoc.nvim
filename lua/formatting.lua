local formatting = {}

formatting.style_elements = {
  header_break = string.rep("=", 78),
}

formatting.indent = function(text_table, indent_level)
  for idx, entry in ipairs(text_table) do
    text_table[idx] = string.rep(" ", indent_level) .. entry
  end
  return text_table
end

return formatting
