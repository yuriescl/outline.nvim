local Float = require('outline.float')
local cfg = require('outline.config')
local providers = require('outline.providers')
local utils = require('outline.utils')

local M = {}

function M.show_help()
  local keyhint = 'Press q or <Esc> to close this window.'
  local title = 'Current keymaps:'
  local lines = { keyhint, '', title, '' }
  ---@type outline.HL[]
  local hl = { { line = 0, from = 0, to = #keyhint, name = 'Comment' } }
  local left = {}
  local right = {}
  local max_left_width = 0
  local indent = '    '
  local key_hl = 'Special'

  for action, keys in pairs(cfg.o.keymaps) do
    if type(keys) == 'string' then
      table.insert(left, keys)
      table.insert(hl, {
        line = #left + 3,
        from = #indent,
        to = #keys + #indent,
        name = key_hl,
      })
    elseif next(keys) == nil then
      table.insert(left, '(none)')
      table.insert(hl, {
        line = #left + 3,
        from = #indent,
        to = #indent + 6,
        name = 'Comment',
      })
    else
      local i = #indent
      table.insert(left, table.concat(keys, ' / '))
      for _, key in ipairs(keys) do
        table.insert(hl, {
          line = #left + 3,
          from = i,
          to = #key + i,
          name = key_hl,
        })
        i = i + #key + 3
      end
    end
    if #left[#left] > max_left_width then
      max_left_width = #left[#left]
    end
    table.insert(right, action)
  end

  for i, l in ipairs(left) do
    local pad = string.rep(' ', max_left_width - #l + 2)
    table.insert(lines, indent .. l .. pad .. right[i])
  end

  local f = Float:new()
  f:open(lines, hl, 'Outline Help', 1)

  utils.nmap(f.bufnr, { 'q', '<Esc>' }, function()
    f:close()
  end)
end

---Display outline window status in a floating window
---@param ctx outline.StatusContext
function M.show_status(ctx)
  local keyhint = 'Press q or <Esc> to close this window.'
  local lines = { keyhint, '' }
  ---@type outline.HL[]
  local hl = { { line = 0, from = 0, to = #keyhint, name = 'Comment' } }
  local p = ctx.provider
  local priority = cfg.o.providers.priority
  local pref

  if utils.table_has_content(priority) then
    pref = 'Configured providers are: '
    table.insert(lines, pref .. table.concat(priority, ', ') .. '.')
    local i = #pref
    for _, name in ipairs(priority) do
      table.insert(hl, { line = #lines - 1, from = i, to = i + #name, name = 'Special' })
      i = i + #name + 2
    end
  else
    pref = 'config '
    local content = 'providers.priority'
    table.insert(lines, pref .. content .. ' is an empty list!')
    table.insert(hl, { line = #lines - 1, from = #pref, to = #pref + #content, name = 'ErrorMsg' })
  end

  table.insert(lines, '')

  if p ~= nil then
    pref = 'Current provider: '
    table.insert(lines, pref .. p.name)
    table.insert(hl, { line = #lines - 1, from = #pref, to = -1, name = 'Special' })
    if p.get_status then
      table.insert(lines, 'Provider info:')
      table.insert(lines, '')
      local l = p.get_status()
      local indent = '    '
      for _, line in ipairs(vim.split(l, '\n', { plain = true, trimempty = false })) do
        table.insert(lines, indent .. line)
      end
    end

    table.insert(lines, '')

    table.insert(
      lines,
      ('Outline window is %s.'):format((ctx.outline_open and 'open') or 'not open')
    )

    table.insert(lines, '')

    if ctx.code_win_active then
      table.insert(lines, 'Code window is active.')
    else
      table.insert(lines, 'Code window is not active!')
      table.insert(lines, 'Try closing and reopening the outline.')
    end
  else
    table.insert(lines, 'No providers.')
  end

  local f = Float:new()
  f:open(lines, hl, 'Outline Status', 1)
  utils.nmap(f.bufnr, { 'q', '<Esc>' }, function()
    f:close()
  end)
end

return M