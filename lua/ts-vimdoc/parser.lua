local Object = require("ts-vimdoc.class")
local handlers = require("ts-vimdoc.handlers")

local Parser = {}

Paser = Object:extend()

function Parser:new(o)
  self.content = o.content
  self.metadata = o.metadata
  return self
end

function Parser:parse()
  assert(self.content)
  local tsparser = vim.treesitter.get_string_parser(self.content, "markdown")
  local tstree = tsparser:parse()[1]
  local parent_node = tstree:root()

  -- local formatted_file = self:recursive_parser(parent_node, self.content)
  local formatted_file = self:recurse(parent_node, self.content)
  table.insert(formatted_file, "\nvim:tw=78:ts=8:ft=help:norl:")

  return table.concat(formatted_file, "\n")
end

Parser.handlers = {
  ["atx_heading"]       = { pre = handlers.heading },
  ["link"]              = { pre = handlers.link },
  ["image"]             = { pre = handlers.link },
  ["inline_link"]       = { pre = handlers.link },
  ["inline"]            = { pre = handlers.inline },
  ["list"]              = { pre = handlers.passthrough },
  ["section"]           = { pre = handlers.passthrough },
  ["strong_emphasis"]   = { pre = handlers.passthrough },
  ["fenced_code_block"] = { pre = handlers.fenced_code_block },
  ["paragraph"]         = {
    pre = handlers.container,
    post = handlers.container_post,
  },
  ["pipe_table"]        = {
    pre = handlers.container,
    post = handlers.container_post,
  },
  ["block_quote"]       = {
    pre = handlers.block_quote,
    post = handlers.block_quote_post,
  },
  ["list_item"]         = {
    pre = handlers.list,
    post = handlers.container_post,
  },
}

function Parser:recurse(parent_node, content, _r)
  if not _r or vim.tbl_isempty(_r) then
    -- recursion stack data
    _r = {
      metadata = self.metadata,
      header_count = 1,
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
    local handler = self.handlers[node_type]
    if not handler then goto continue end

    if handler.pre then
      -- handler also replaces 'inline' nodes
      -- with the new 'markdown_inline' parser
      node, content = handler.pre(node, content, _r)
      if node and node:child_count() > 0 then
        self:recurse(node, content, _r)
      end
    end
    if handler.post then
      handler.post(node, content, _r)
    end

    ::continue::
  end

  return _r.parsed_content
end

return Parser
