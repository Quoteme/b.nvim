-- The side panels of the animation and of interactive proofs: lines of
-- highlighted text, each with the item it shows.
local M = {}

---@class prob.Line
---@field text string
---@field marks {[1]: integer, [2]: integer, [3]: string}[] column ranges and highlight groups
---@field item? table

---@return prob.Line
function M.line(item)
  return { text = '', marks = {}, item = item }
end

--- Appends `text` to `l`, highlighted with `group`.
function M.put(l, text, group)
  if group then
    table.insert(l.marks, { #l.text, #l.text + #text, group })
  end
  l.text = l.text .. text
  return l
end

function M.pad(text, width)
  return text .. string.rep(' ', math.max(1, width - vim.fn.strdisplaywidth(text)))
end

--- Shows `lines` in `buf`, highlighted in namespace `ns`.
---@param lines prob.Line[]
---@return table<integer, table> items line number → item under it
function M.draw(buf, ns, lines)
  local items, text = {}, {}
  for i, l in ipairs(lines) do
    text[i] = l.text
    items[i] = l.item
  end
  vim.bo[buf].modifiable = true
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, text)
  vim.bo[buf].modifiable = false
  vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
  for i, l in ipairs(lines) do
    for _, m in ipairs(l.marks) do
      vim.api.nvim_buf_set_extmark(buf, ns, i - 1, m[1], { end_col = m[2], hl_group = m[3] })
    end
  end
  return items
end

--- Opens a scratch buffer named `name` in a vertical split on the right.
---@return integer buf, integer win
function M.open(name, filetype, width)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].buftype = 'nofile'
  vim.bo[buf].bufhidden = 'wipe'
  vim.bo[buf].swapfile = false
  vim.bo[buf].filetype = filetype
  vim.api.nvim_buf_set_name(buf, name)

  vim.cmd(('botright vertical %dsplit'):format(width))
  local win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(win, buf)
  for option, value in pairs({
    number = false,
    relativenumber = false,
    signcolumn = 'no',
    foldcolumn = '0',
    wrap = false,
    cursorline = true,
    winfixwidth = true,
    spell = false,
    list = false,
    statuscolumn = '',
  }) do
    vim.wo[win][option] = value
  end
  return buf, win
end

return M
