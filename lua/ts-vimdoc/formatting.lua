local formatting = {}

formatting.style_elements = {
  header_break = {
    string.rep("=", 78), -- atx_h1_marker
    string.rep("-", 78), -- atx_h2_marker
    string.rep(" ", 78), -- atx_h3_marker
    string.rep(" ", 78), -- atx_h4_marker
  },
}

formatting.indent = function(text_table, indent_level)
  for idx, entry in ipairs(text_table) do
    text_table[idx] = string.rep(" ", indent_level) .. entry
  end
  return text_table
end

formatting.line3 = function(left, center, right, pad_char)
  local max_width = 76
  pad_char = pad_char or " "
  local padding = string.rep(pad_char, max_width - #left - #right)
  center = center or padding
  if #padding > #center then
    local extra = #padding - #center
    center = string.format("%s%s%s",
      string.rep(pad_char, extra / 2 + extra % 2),
      center,
      string.rep(pad_char, extra / 2))
  end
  return string.format("%s %s %s", left, center, right)
end

return formatting
