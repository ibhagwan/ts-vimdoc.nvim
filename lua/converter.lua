local formatting = require('formatting')
local get_node_text = require('vim.treesitter.query').get_node_text

local function lua_escape(str)
  -- escape all lua special chars
  -- ( ) % . + - * [ ? ^ $
  if not str then return str end
  return str:gsub('[%(%)%.%+%-%*%[%?%^%$%%]', function(x)
    return '%' .. x
  end)
end

local make_paragraph = function(line_parts, opts)
  local text = table.concat(line_parts)
  if opts.in_block_quote then
    -- remove preceding spaces and '>'
    text = text:gsub("^>", ""):gsub("\n%s->", "\n")
  end
  -- table hack
  local raw_wrapped, is_table = text:gsub("^|(.*)|\n", "<raw>|%1|<NL></raw>")
  if is_table and is_table>0 then
    text = raw_wrapped:gsub("<NL></raw>", "</raw>")
  end
  local res = {}
  local line = nil
  local start_idx, end_idx = 1, nil
  local pattern = opts.strip_newlines and "%s\n" or "%s"
  local function insert_line(l)
    if not l then return end
    if opts.in_block_quote and opts.in_block_quote>0 then
      l = string.rep(" ", opts.in_block_quote*2) .. line
    end
    table.insert(res, l)
    return nil
  end
  repeat
    start_idx = text:find("[^"..pattern.."]+", start_idx)
    if start_idx then
      if text:sub(start_idx):match("^<raw>") then
        if line and #line>0 then
          -- first insert the leftover line
          line = insert_line(line)
        end
        end_idx = text:find("</raw>", start_idx)
        local raw = text:sub(start_idx+5, end_idx-1):gsub("<NL>", "\n")
        end_idx = end_idx+6
        -- insert raw, no block quote indent
        table.insert(res, raw)
      else
        end_idx = text:find("["..pattern.."]", start_idx)
        local word = text:sub(start_idx, end_idx and end_idx-1 or #text)
        if not line then
          line = word
        elseif (#line + #word + 1) > 78 then
          insert_line(line)
          line = (opts.in_list and "  " or "") .. word
        else
          line = line .. " " .. word
        end
      end
      start_idx = end_idx
    end
  until (not start_idx or start_idx>#text-1)
  -- insert leftover line
  insert_line(line)
  if not opts.in_list or not is_table then
    -- newline after paragraphs
    vim.list_extend(res, {''})
  end
  return res
end

local converter = {}

converter.fenced_code_block = function(node, content, _r)
  local text_orig = get_node_text(node, content)
  for child_node in node:iter_children() do
    if child_node:type() == 'code_fence_content' then
      node = child_node
    end
  end
  local codeblock_content = vim.split(get_node_text(node, content):gsub("\n>?%s-$", ""), "\n")
  codeblock_content = formatting.indent(codeblock_content, 4)
  local lines = {}
  vim.list_extend(lines, {">"})
  vim.list_extend(lines, codeblock_content)
  vim.list_extend(lines, {"<"})
  if _r.container_text then
    local text = "<raw>"..table.concat(lines, "<NL>").."</raw>"
    _r.container_text = _r.container_text:gsub(
      lua_escape(text_orig), text)
  else
    vim.list_extend(_r.parsed_content, lines)
  end
  return false, content
end

converter.heading = function(node, content, _r)
  local header_level = 1
  local metadata = converter.metadata
  for child in node:iter_children() do
    local child_type = child:type()
    if child_type == 'atx_h2_marker' then
      header_level = 2
    elseif child_type == 'atx_h3_marker' then
      header_level = 3
    end
  end
  local text = get_node_text(node, content)
  text = text:gsub("#+%s", ""):gsub("\n", "")
  local header_prefix = ''
  if metadata.header_count_lvl and header_level <= metadata.header_count_lvl then
    header_prefix = ("%d. "):format(_r.header_count)
    _r.header_count = _r.header_count + 1
  end
  local left = string.format("%s%s", header_prefix, string.upper(text))
  local right = string.lower(string.gsub(text, "%s", "-"))
  right = string.format("*%s-%s*", metadata.project_name, right)
  local padding = string.rep(" ", 78 - #left - #right)
  text = string.format("%s%s%s", left, padding, right)
  local lines = {}
  if not vim.tbl_isempty(_r.parsed_content) then
    vim.list_extend(lines, {''})
  end
  vim.list_extend(lines,
    {formatting.style_elements.header_break[header_level], text, ''})
  if header_level <= 2 then
    vim.list_extend(lines, {''})
  end
  vim.list_extend(_r.parsed_content, lines)
  return false, content
end

converter.link = function(node, content, _r)
  local link_text, link_dest
  local link_orig = get_node_text(node, content)
  for child in node:iter_children() do
    local child_type = child:type()
    if child_type == 'link_text' or
       child_type == 'image_description' then
      link_text = get_node_text(child, content)
    elseif child_type == 'link_destination' then
      link_dest = get_node_text(child, content)
    end
  end
  if link_text and link_dest then
    local text = ("%s <%s>"):format(link_text, link_dest)
    if _r.container_text then
      _r.container_text = _r.container_text:gsub(lua_escape(link_orig), text)
    else
      vim.list_extend(_r.parsed_content, {text})
    end
  end
  return false, content
end

converter.container = function(node, content, _r)
  _r.container_opts = _r.container_opts or { strip_newlines = true }
  _r.container_ref = _r.container_ref and _r.container_ref+1 or 1
  if _r.container_ref == 1 then
    _r.container_text = get_node_text(node, content)
  end
  return node, content
end

converter.container_post = function(_, _, _r)
  assert(_r.container_text and _r.container_ref)
  _r.container_ref = _r.container_ref>1 and _r.container_ref-1 or nil
  if not _r.container_ref then
    vim.list_extend(_r.parsed_content,
      make_paragraph({_r.container_text}, _r.container_opts))
    _r.container_text = nil
    _r.container_opts = nil
  end
end

converter.block_quote = function(node, content, _r)
  _r.in_block_quote = _r.in_block_quote and _r.in_block_quote+1 or 1
  _r.container_opts = _r.container_opts or {
    strip_newlines = true,
    in_block_quote = _r.in_block_quote,
  }
  return converter.container(node, content, _r)
end

converter.block_quote_post = function(node, content, _r)
  assert(_r.in_block_quote)
  _r.in_block_quote = _r.in_block_quote>1 and _r.in_block_quote-1 or nil
  return converter.container_post(node, content, _r)
end

converter.list = function(node, content, _r)
  _r.in_list = _r.in_list and _r.in_list+1 or 1
  _r.container_opts = _r.container_opts or {
    strip_newlines = true,
    in_list = _r.in_list
  }
  return converter.container(node, content, _r)
end

converter.list_post = function(node, content, _r)
  assert(_r.in_list)
  _r.in_list = _r.in_list>1 and _r.in_list-1 or nil
  return converter.container_post(node, content, _r)
end


converter.inline = function(node, content, _)
 -- new parser for 'markdown_inline' see:
  -- https://github.com/MDeiml/tree-sitter-markdown/issues/45
  local node_text = get_node_text(node, content)
  local inline_parser = vim.treesitter.get_string_parser(
    node_text, "markdown_inline")
  local tstree = inline_parser:parse()[1]
  return tstree:root(), node_text
end

converter.passthrough = function(node, content, _) return node, content end

converter.handlers = {
  ['atx_heading']         = { pre = converter.heading },
  ['link']                = { pre = converter.link },
  ['image']               = { pre = converter.link },
  ['inline_link']         = { pre = converter.link },
  ['inline']              = { pre = converter.inline },
  ['list']                = { pre = converter.passthrough },
  ['section']             = { pre = converter.passthrough },
  ['strong_emphasis']     = { pre = converter.passthrough },
  ['fenced_code_block']   = { pre = converter.fenced_code_block },
  ['paragraph'] = {
    pre = converter.container,
    post = converter.container_post,
  },
  ['block_quote'] = {
    pre = converter.block_quote,
    post = converter.block_quote_post,
  },
  ['list_item'] = {
    pre = converter.list,
    post = converter.container_post,
  },
}

converter.recursive_parser = function(parent_node, content, _r)
  if not _r or vim.tbl_isempty(_r) then
    -- recursion stack data
    _r = {
      header_count = 1,
      line_parts = {},
      parsed_content = {},
    }
  end

  for node in parent_node:iter_children() do

    -- print("processing ", node:type(), node:named())

    -- do not parse anonymous nodes
    if not node:named() then
      goto continue
    end

    local node_type = node:type()
    local handler = converter.handlers[node_type]
    if not handler then goto continue end

    if handler.pre then
      -- handler also replaces 'inline' nodes
      -- with the new 'markdown_inline' parser
      node, content = handler.pre(node, content, _r)
      if node and node:child_count() > 0 then
        converter.recursive_parser(node, content, _r)
      end
    end
    if handler.post then
      handler.post(node, content, _r)
    end

    ::continue::
  end

  return _r.parsed_content
end

return converter
