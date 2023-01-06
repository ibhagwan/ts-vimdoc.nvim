local Object = require("ts-vimdoc.class")
local format = require("ts-vimdoc.formatting")
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

  local formatted_file, context = self:recurse(parent_node, self.content)
  if self.metadata.table_of_contents ~= false then
    formatted_file = self:insert_table_of_contents(formatted_file, context.headers)
  end
  table.insert(formatted_file, 1, self:header_line())
  table.insert(formatted_file, 2, "")
  table.insert(formatted_file, "\nvim:tw=78:ts=8:ft=help:norl:")

  return table.concat(formatted_file, "\n")
end

function Parser:header_line()
  -- if this remains nil, localtime will be used
  local last_commit_timestamp = nil
  -- Attempt to acquire the last commit modification
  -- date for the input file from the git repo
  if not self.metadata.last_change_from_now then
    local result = vim.fn.system({
      "git",
      "-C",
      vim.fn.fnamemodify(self.metadata.input_file, ":h"),
      "--no-pager",
      "log",
      "-1",
      [[--pretty=format:"%cI"]],
      vim.fn.fnamemodify(self.metadata.input_file, ":t"),
    })
    if vim.v.shell_error == 0 then
      local year, month, day = result:match("(%d+)%-(%d+)%-(%d+)")
      last_commit_timestamp = os.time({ year = year, month = month, day = day })
    end
  end
  return format.line3(
    string.format("*%s*", vim.fn.fnamemodify(self.metadata.output_file, ":t")),
    self.metadata.version,
    os.date("Last change: %Y %B %d", last_commit_timestamp))
end

function Parser:insert_table_of_contents(tbl, headers)
  if not headers or vim.tbl_isempty(headers) then
    return tbl
  end
  table.insert(tbl, 1, string.rep("=", 78))
  table.insert(tbl, 2, format.line3("Table of Contents", nil,
    string.format("*%s-table-of-contents*", self.metadata.project_name)))
  table.insert(tbl, 3, "")
  local start_idx = 3
  for i, h in ipairs(headers) do
    local tag = h.tag:gsub("^*", "|"):gsub("*$", "|")
    table.insert(tbl, start_idx + i, format.line3(h.title, nil, tag, "."))
    -- local prefix = string.rep(".", 2 * (h.lvl - 1))
    -- table.insert(tbl, start_idx + i, format.line3(prefix .. h.title, nil, tag))
  end
  table.insert(tbl, start_idx + #headers + 1, "")
  return tbl
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
      headers = {},
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

  return _r.parsed_content, _r
end

return Parser
