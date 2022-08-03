-- help to inspect results, e.g.:
-- ':lua _G.dump(vim.fn.getwininfo())'
-- use ':messages' to see the dump
function _G.dump(...)
  local objects = vim.tbl_map(vim.inspect, { ... })
  print(unpack(objects))
end

local M = {}

function M.info(msg)
  vim.cmd('echohl Directory')
  M._echo_multiline("[ts-vimdoc] " .. msg)
  vim.cmd('echohl None')
end

function M.warn(msg)
  vim.cmd('echohl WarningMsg')
  M._echo_multiline("[ts-vimdoc] " .. msg)
  vim.cmd('echohl None')
end

function M.err(msg)
  vim.cmd('echohl ErrorMsg')
  M._echo_multiline("[ts-vimdoc] " .. msg)
  vim.cmd('echohl None')
end

return M
