-- Rodin's keyboard for Event-B buffers: ASCII combinations such as `:` or
-- `-->` become their Unicode symbols (`∈`, `→`) while typing, once the next
-- character shows that the combination is complete. Combinations made of
-- letters (`NAT`, `or`, `POW`) are only replaced as whole words.
local M = {}

local operators, words, prefixes, operator_chars = {}, {}, {}, {}
for _, entry in ipairs(require('prob.symbols')) do
  local combo, symbol = entry[1], entry[2]
  if combo:match('^[%w_]+$') then
    words[combo] = symbol
  else
    operators[combo] = symbol
    for i = 1, #combo do
      prefixes[combo:sub(1, i)] = true
      operator_chars[combo:sub(i, i)] = true
    end
  end
end

--- Replaces the combinations in a run of operator characters, longest first.
---@param run string
---@return string
local function translate(run)
  local out, i = {}, 1
  while i <= #run do
    local match
    for length = math.min(5, #run - i + 1), 1, -1 do
      local piece = run:sub(i, i + length - 1)
      if operators[piece] then
        match = piece
        break
      end
    end
    out[#out + 1] = match and operators[match] or run:sub(i, i)
    i = i + (match and #match or 1)
  end
  return table.concat(out)
end

local function is_word_char(char)
  return char ~= nil and char ~= '' and (char:match('[%w_]') ~= nil or char:byte() >= 128)
end

--- Whether the text before (row, col) lies in a comment or label, which keep their spelling.
local function verbatim(buf, row, col)
  local ok, parser = pcall(vim.treesitter.get_parser, buf)
  if not ok or not parser or col == 0 then
    return false
  end
  parser:parse({ row, row + 1 })
  local node = vim.treesitter.get_node({ bufnr = buf, pos = { row, col - 1 }, ignore_injections = true })
  while node do
    if node:type() == 'comment' or node:type() == 'label' then
      return true
    end
    node = node:parent()
  end
  return false
end

--- Replaces the combination that ends at byte `col` (0-based, exclusive) of
--- `row` and is followed by `next`, or by nothing at the end of the input.
---@return integer change of the line's length
local function settle(buf, row, col, next)
  local line = vim.api.nvim_buf_get_lines(buf, row, row + 1, true)[1]
  local text = line:sub(1, col)
  if verbatim(buf, row, col) then
    return 0
  end

  local run = text:match('[%p]*$')
  local start = #text - #run
  while #run > 0 and not operator_chars[run:sub(1, 1)] do
    run = run:sub(2)
    start = start + 1
  end
  if run:find('//', 1, true) or run:find('/*', 1, true) or (next == '/' and run:sub(-1) == '/') or (next == '*' and run:sub(-1) == '/') then
    return 0
  end

  local replacement, stop
  if #run > 0 then
    -- Keep the longest tail that the next character may still complete.
    local pending = 0
    if next and operator_chars[next] then
      local tail = run .. next
      for length = #tail, 1, -1 do
        if prefixes[tail:sub(-length)] then
          pending = length - 1
          break
        end
      end
    end
    local head = run:sub(1, #run - pending)
    if #head == 0 then
      return 0
    end
    replacement, stop = translate(head), start + #head
  elseif not is_word_char(next) then
    local word = text:match('[%w_]+$')
    local before = word and text:sub(#text - #word, #text - #word)
    if not word or not words[word] or is_word_char(before) or before == '@' then
      return 0
    end
    start, stop, replacement = #text - #word, #text, words[word]
  else
    return 0
  end

  if replacement == line:sub(start + 1, stop) then
    return 0
  end
  vim.api.nvim_buf_set_text(buf, row, start, row, stop, { replacement })
  return #replacement - (stop - start)
end

--- Translates the combinations typed on `row` between `state.col` and `col`,
--- character by character, so that keys typed faster than TextChangedI fires
--- are not missed.
---@return integer the new column of `col`
local function process(buf, state, row, col)
  local line = vim.api.nvim_buf_get_lines(buf, row, row + 1, true)[1]
  local pos = state.row == row and math.min(state.col or col, col) or col
  while pos < col do
    local length = #vim.fn.strcharpart(line:sub(pos + 1), 0, 1)
    local delta = settle(buf, row, pos, line:sub(pos + 1, pos + length))
    pos, col = pos + delta + length, col + delta
    line = vim.api.nvim_buf_get_lines(buf, row, row + 1, true)[1]
  end
  return col
end

local function on_change(buf, state)
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  row = row - 1
  if state.row and state.row ~= row then
    -- A new line was started: the previous one ends here.
    if state.row < vim.api.nvim_buf_line_count(buf) then
      local previous = vim.api.nvim_buf_get_lines(buf, state.row, state.row + 1, true)[1]
      local done = process(buf, state, state.row, #previous)
      settle(buf, state.row, done, nil)
    end
    state.row, state.col = row, 0
  end
  local moved = process(buf, state, row, col)
  if moved ~= col then
    vim.api.nvim_win_set_cursor(0, { row + 1, moved })
  end
  state.row, state.col, state.tick = row, moved, vim.b[buf].changedtick
end

--- Enables the keyboard in `buf`.
---@param buf integer
function M.attach(buf)
  local group = vim.api.nvim_create_augroup('prob_keyboard_' .. buf, { clear = true })
  local state = {}
  local function reset()
    local cursor = vim.api.nvim_win_get_cursor(0)
    state.row, state.col, state.tick = cursor[1] - 1, cursor[2], vim.b[buf].changedtick
  end
  vim.api.nvim_create_autocmd('InsertEnter', { group = group, buffer = buf, callback = reset })
  vim.api.nvim_create_autocmd('CursorMovedI', {
    group = group,
    buffer = buf,
    callback = function()
      -- Moving without typing starts over at the new position.
      if state.tick == vim.b[buf].changedtick then
        reset()
      end
    end,
  })
  vim.api.nvim_create_autocmd('TextChangedI', {
    group = group,
    buffer = buf,
    callback = function()
      on_change(buf, state)
    end,
  })
  vim.api.nvim_create_autocmd('InsertLeave', {
    group = group,
    buffer = buf,
    callback = function()
      local mark = vim.api.nvim_buf_get_mark(buf, '^')
      local row = mark[1] - 1
      if state.row and state.row ~= row and state.row < vim.api.nvim_buf_line_count(buf) then
        local previous = vim.api.nvim_buf_get_lines(buf, state.row, state.row + 1, true)[1]
        settle(buf, state.row, process(buf, state, state.row, #previous), nil)
        state.row, state.col = row, 0
      end
      settle(buf, row, process(buf, state, row, mark[2]), nil)
      state.row = nil
    end,
  })
end

--- Translates every combination in a string, as if it had been typed.
---@param text string
---@return string
function M.translate(text)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].filetype = 'eventb'
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, { '' })
  local line = ''
  for _, char in ipairs(vim.fn.split(text, '\\zs')) do
    settle(buf, 0, #line, char)
    line = vim.api.nvim_buf_get_lines(buf, 0, 1, true)[1] .. char
    vim.api.nvim_buf_set_lines(buf, 0, 1, true, { line })
  end
  settle(buf, 0, #line, nil)
  line = vim.api.nvim_buf_get_lines(buf, 0, 1, true)[1]
  vim.api.nvim_buf_delete(buf, { force = true })
  return line
end

--- Lets the user pick a symbol and inserts it at the cursor.
function M.pick()
  local insert = vim.fn.mode():find('i') ~= nil
  local win, buf = vim.api.nvim_get_current_win(), vim.api.nvim_get_current_buf()
  local cursor = vim.api.nvim_win_get_cursor(win)
  local seen, items = {}, {}
  for _, entry in ipairs(require('prob.symbols')) do
    if not seen[entry[2]] then
      seen[entry[2]] = true
      table.insert(items, entry)
    end
  end
  vim.ui.select(items, {
    prompt = 'Event-B symbol',
    format_item = function(entry)
      return ('%s  %-7s %s'):format(entry[2], entry[1], entry[3])
    end,
  }, function(entry)
    if not entry then
      return
    end
    vim.api.nvim_set_current_win(win)
    local row, col = cursor[1] - 1, cursor[2]
    if not insert then
      local line = vim.api.nvim_buf_get_lines(buf, row, row + 1, true)[1]
      col = math.min(#line, col + #vim.fn.strcharpart(line:sub(col + 1), 0, 1))
    end
    vim.api.nvim_buf_set_text(buf, row, col, row, col, { entry[2] })
    vim.api.nvim_win_set_cursor(win, { row + 1, insert and col + #entry[2] or col })
    if insert and not vim.fn.mode():find('i') then
      vim.cmd('startinsert')
    end
  end)
end

return M
