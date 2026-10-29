-- Animates a machine with ProB, like the Events, State and History views of
-- ProB for Rodin: a side panel lists the enabled events, the current state and
-- the history, and the model's source shows the current values inline.
local M = {}

local ns = vim.api.nvim_create_namespace('prob_animation')
local panel_ns = vim.api.nvim_create_namespace('prob_animation_panel')

---@class prob.Animation
---@field client vim.lsp.Client
---@field source integer buffer of the animated model
---@field buf? integer panel buffer
---@field win? integer panel window
---@field view? table last view sent by the server
---@field items table<integer, table> panel line → item under it
---@field busy boolean
---@field stale boolean the model was saved since the animation started
---@field help boolean
---@field expanded boolean the VISUALIZE section lists its entries
---@field last? table result of the last visualisation
local session

local highlights = {
  ProbAnimTitle = 'Title',
  ProbAnimSection = 'Statement',
  ProbAnimEnabled = 'DiagnosticOk',
  ProbAnimDisabled = 'Comment',
  ProbAnimEvent = 'Function',
  ProbAnimParameter = 'Comment',
  ProbAnimName = 'Identifier',
  ProbAnimValue = 'String',
  ProbAnimChanged = 'DiagnosticWarn',
  ProbAnimOk = 'DiagnosticOk',
  ProbAnimFail = 'DiagnosticError',
  ProbAnimCurrent = 'Special',
  ProbAnimFuture = 'Comment',
  ProbAnimMessage = 'WarningMsg',
  ProbAnimHelp = 'Comment',
  ProbAnimKey = 'Special',
  ProbAnimCell = 'Normal',
  ProbAnimOpen = 'Underlined',
}
for group, link in pairs(highlights) do
  vim.api.nvim_set_hl(0, group, { link = link, default = true })
end

local keys = {
  { '<CR>', 'execute the event, go to the history step, or show the source' },
  { 'p', 'execute an event with a parameter predicate' },
  { 'u', 'step back ([count])' },
  { '<C-r>', 'step forward ([count])' },
  { 'r', 'execute [count] random events' },
  { 'f', 'find a state satisfying a predicate' },
  { 'm', 'model check from here; jump to a counterexample' },
  { 'v', 'show a visualisation of the state (graph, table)' },
  { 'I', 'open the graphical animation with its images, or VisB' },
  { 'gd', 'show the source of the item' },
  { 'R', 'restart the animation' },
  { 'q', 'stop the animation' },
  { '?', 'toggle this help' },
}

-- ---------------------------------------------------------------------------
-- Rendering

local panel = require('prob.panel')
local line, put, pad = panel.line, panel.put, panel.pad

--- The name of a visualisation, without the "..." of ProB Tcl/Tk's menu entries.
local function label(v)
  return (v.name:gsub('%.%.%.$', ''))
end

local function render_lines(view)
  local lines = {}
  local function add(l)
    table.insert(lines, l)
  end
  local function section(title)
    add(line())
    add(put(line(), ' ' .. title, 'ProbAnimSection'))
  end

  local title = put(line(), ' ◆ ProB', 'ProbAnimTitle')
  put(title, ' · ' .. (view.machine or ''), 'ProbAnimTitle')
  if view.step then
    put(title, ('   step %d'):format(view.step), 'ProbAnimHelp')
  end
  if session.busy then
    put(title, '  …', 'ProbAnimMessage')
  end
  add(title)
  if session.stale then
    add(put(line(), ' model changed · R restarts', 'ProbAnimMessage'))
  end
  if view.message and view.message ~= '' then
    add(put(line(), ' ' .. view.message, 'ProbAnimMessage'))
  end
  if view.error then
    add(put(line(), ' ' .. view.error, 'ProbAnimFail'))
    return lines
  end

  section('EVENTS')
  local width = 4
  for _, e in ipairs(view.enabled or {}) do
    width = math.max(width, vim.fn.strdisplaywidth(e.name) + 2)
  end
  for _, e in ipairs(view.disabled or {}) do
    width = math.max(width, vim.fn.strdisplaywidth(e.name) + 2)
  end
  for _, e in ipairs(view.enabled or {}) do
    local l = put(line(vim.tbl_extend('force', e, { kind = 'event' })), '   ▶ ', 'ProbAnimEnabled')
    put(l, pad(e.name, width), 'ProbAnimEvent')
    put(l, e.parameters or '', 'ProbAnimParameter')
    add(l)
  end
  for _, e in ipairs(view.disabled or {}) do
    local l = put(line(vim.tbl_extend('force', e, { kind = 'disabled' })), '   ○ ', 'ProbAnimDisabled')
    put(l, pad(e.name, width), 'ProbAnimDisabled')
    for _, g in ipairs(e.guards or {}) do
      if g.ok == false then
        put(l, g.label .. ' ✗ ', 'ProbAnimFail')
      end
    end
    add(l)
  end
  if view.deadlock then
    add(put(line(), '   ⚠ deadlock: no event is enabled', 'ProbAnimFail'))
  end

  local function values(title_text, entries)
    if #entries == 0 then
      return
    end
    section(title_text)
    local w = 4
    for _, v in ipairs(entries) do
      w = math.max(w, vim.fn.strdisplaywidth(v.name) + 2)
    end
    for _, v in ipairs(entries) do
      local l = put(line(vim.tbl_extend('force', v, { kind = 'value' })), '   ')
      put(l, pad(v.name, w), 'ProbAnimName')
      put(l, v.value or '?', v.changed and 'ProbAnimChanged' or 'ProbAnimValue')
      if v.changed then
        put(l, ' *', 'ProbAnimChanged')
      end
      add(l)
    end
  end
  values('STATE', view.initialised and view.variables or {})
  values('CONSTANTS', view.constantsSetUp and view.constants or {})

  if #(view.invariants or {}) > 0 then
    section(view.context and 'AXIOMS' or 'INVARIANTS')
    local l = put(line(), '  ')
    for _, inv in ipairs(view.invariants) do
      local mark = inv.ok == true and '✓' or (inv.ok == false and '✗' or '?')
      local group = inv.ok == false and 'ProbAnimFail' or (inv.ok and 'ProbAnimOk' or 'ProbAnimDisabled')
      if vim.fn.strdisplaywidth(l.text) + #inv.label + 4 > 44 then
        add(l)
        l = put(line(), '  ')
      end
      put(l, ' ' .. mark .. ' ' .. inv.label, group)
      l.item = l.item or vim.tbl_extend('force', inv, { kind = 'invariant' })
    end
    add(l)
  end
  for _, e in ipairs(view.errors or {}) do
    add(put(line(), '   ⚠ ' .. e, 'ProbAnimFail'))
  end

  -- ANIMATION_FUNCTION, drawn as text; its images and VisB open in a viewer.
  if (view.graphics and #view.graphics > 0) or view.visb then
    section('GRAPHICS')
  end
  if view.graphics and #view.graphics > 0 then
    local widths, images = {}, false
    for _, row in ipairs(view.graphics) do
      for c, cell in ipairs(row) do
        widths[c] = math.max(widths[c] or 1, vim.fn.strdisplaywidth(cell.text or ''))
        images = images or cell.image ~= nil
      end
    end
    for _, row in ipairs(view.graphics) do
      local l = put(line({ kind = 'graphics' }), '   ')
      for c, cell in ipairs(row) do
        local text = c < #row and pad(cell.text or '', widths[c] + 1) or (cell.text or '')
        put(l, text, cell.image and 'ProbAnimValue' or 'ProbAnimCell')
      end
      add(l)
    end
    if images then
      add(put(line({ kind = 'graphics' }), '   ⧉ show with images', 'ProbAnimOpen'))
    end
  end
  if view.visb then
    add(put(line({ kind = 'visb' }), '   ⧉ show VisB', 'ProbAnimOpen'))
  end

  -- The Visualize menu of ProB Tcl/Tk: graphs open in a viewer, tables in a split.
  local available = vim.tbl_filter(function(v)
    return v.available
  end, view.visualizations or {})
  if #available > 0 then
    add(line())
    local l = put(line({ kind = 'visualizations' }), ' VISUALIZE', 'ProbAnimSection')
    put(l, session.expanded and '' or (' ▸ %d · ⏎ expands'):format(#available), 'ProbAnimHelp')
    add(l)
    if session.expanded then
      for _, v in ipairs(available) do
        local entry = put(line(vim.tbl_extend('force', v, { kind = 'visualization' })), v.kind == 'table' and '   ▤ ' or '   ⧉ ', 'ProbAnimOpen')
        put(entry, label(v), nil)
        add(entry)
      end
    end
  end

  if #(view.history or {}) > 0 then
    section('HISTORY')
    for _, h in ipairs(view.history) do
      local current = h.index == view.step
      local l = put(line(vim.tbl_extend('force', h, { kind = 'history' })), current and ' ▸ ' or '   ', 'ProbAnimCurrent')
      put(l, ('%2d '):format(h.index), h.future and 'ProbAnimFuture' or 'ProbAnimHelp')
      put(l, h.label, h.future and 'ProbAnimFuture' or (current and 'ProbAnimCurrent' or nil))
      add(l)
    end
  end

  add(line())
  if session.help then
    for _, k in ipairs(keys) do
      local l = put(line(), ' ' .. pad(k[1], 7), 'ProbAnimKey')
      put(l, k[2], 'ProbAnimHelp')
      add(l)
    end
  else
    local l = line()
    for i, k in ipairs({ { '⏎', 'run' }, { 'p', 'with' }, { 'u', 'back' }, { 'r', 'random' }, { '?', 'help' } }) do
      put(l, (i == 1 and ' ' or ' · ') .. k[1], 'ProbAnimKey')
      put(l, ' ' .. k[2], 'ProbAnimHelp')
    end
    add(l)
  end
  return lines
end

--- Shows the current values next to their declarations in the model's buffers.
local function annotate(view)
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
  end
  if not view or view.error then
    return
  end
  local function mark(item, chunks)
    if not item.uri or not item.line then
      return
    end
    local buf = vim.uri_to_bufnr(item.uri)
    if not vim.api.nvim_buf_is_loaded(buf) or item.line >= vim.api.nvim_buf_line_count(buf) then
      return
    end
    vim.api.nvim_buf_set_extmark(buf, ns, item.line, 0, { virt_text = chunks, hl_mode = 'combine' })
  end
  -- Several declarations may share a line, so collect the chunks per line.
  local byline = {}
  local function collect(item, chunks)
    if not item.uri or not item.line then
      return
    end
    local key = item.uri .. ':' .. item.line
    if not byline[key] then
      byline[key] = { item = item, chunks = {} }
    end
    vim.list_extend(byline[key].chunks, chunks)
  end
  for _, v in ipairs(view.initialised and view.variables or {}) do
    collect(v, { { '  ' .. v.name .. ' = ', 'ProbAnimHelp' }, { v.value or '?', v.changed and 'ProbAnimChanged' or 'ProbAnimValue' } })
  end
  for _, c in ipairs(view.constantsSetUp and view.constants or {}) do
    collect(c, { { '  ' .. c.name .. ' = ', 'ProbAnimHelp' }, { c.value or '?', 'ProbAnimValue' } })
  end
  for _, inv in ipairs(view.invariants or {}) do
    collect(inv, { { inv.ok == false and '  ✗' or '  ✓', inv.ok == false and 'ProbAnimFail' or 'ProbAnimOk' } })
  end
  local events = {}
  for _, e in ipairs(view.enabled or {}) do
    events[e.name] = events[e.name] or e
  end
  for _, e in pairs(events) do
    collect(e, { { '  ▶ enabled', 'ProbAnimEnabled' } })
  end
  for _, entry in pairs(byline) do
    mark(entry.item, entry.chunks)
  end
end

local function render()
  if not session or not session.buf or not vim.api.nvim_buf_is_valid(session.buf) then
    return
  end
  session.items = panel.draw(session.buf, panel_ns, render_lines(session.view or {}))
  annotate(session.view)
end

--- Shows a table visualisation in a split below the model.
local function show_table(result)
  local rows = { result.header or {} }
  vim.list_extend(rows, result.rows or {})
  local widths = {}
  for _, row in ipairs(rows) do
    for c, cell in ipairs(row) do
      widths[c] = math.max(widths[c] or 0, vim.fn.strdisplaywidth(cell))
    end
  end
  local lines = {}
  for r, row in ipairs(rows) do
    local cells = {}
    for c, cell in ipairs(row) do
      cells[c] = c < #row and pad(cell, widths[c] + 2) or cell
    end
    table.insert(lines, table.concat(cells))
    if r == 1 then
      local rule = {}
      for c, w in ipairs(widths) do
        rule[c] = string.rep('─', w) .. (c < #widths and '  ' or '')
      end
      table.insert(lines, table.concat(rule))
    end
  end
  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].bufhidden = 'wipe'
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false
  vim.bo[buf].filetype = 'probtable'
  pcall(vim.api.nvim_buf_set_name, buf, 'ProB: ' .. (result.title or 'table'))
  vim.api.nvim_buf_set_extmark(buf, panel_ns, 0, 0, { end_row = 1, hl_group = 'ProbAnimSection', hl_eol = true })
  local source = vim.fn.bufwinid(session and session.source or -1)
  if source ~= -1 then
    vim.api.nvim_set_current_win(source)
  end
  vim.cmd(('belowright %dsplit'):format(math.min(#lines, 15)))
  vim.api.nvim_win_set_buf(0, buf)
  vim.wo.wrap = false
  vim.keymap.set('n', 'q', '<Cmd>close<CR>', { buffer = buf, nowait = true, desc = 'ProB: close table' })
end

--- Opens a file ProB rendered, with `visualization.open` or the system's viewer.
local function open_file(path)
  local open = require('prob').config.visualization.open
  if open then
    return open(path)
  end
  local _, err = vim.ui.open(path)
  if err then
    vim.notify(('prob: cannot open %s: %s'):format(path, err), vim.log.levels.ERROR)
  end
end

-- ---------------------------------------------------------------------------
-- Talking to the server

--- Sends one animation action and shows the resulting view.
local function request(action, argument, count)
  if not session or session.busy then
    return
  end
  session.busy = true
  render()
  local args = {
    action = action,
    uri = vim.uri_from_bufnr(session.source),
    argument = argument,
    count = count,
  }
  session.client:request('workspace/executeCommand', { command = 'prob.animate', arguments = { args } }, function(err, result)
    if not session then
      return
    end
    session.busy = false
    if err then
      session.view = vim.tbl_extend('force', session.view or {}, { message = err.message })
    elseif result then
      session.view = result
      if action == 'start' or action == 'restart' then
        session.stale = false
      end
    end
    render()
  end, session.source)
end

--- Asks the server for a visualisation of the current state and shows it.
---@param kind 'graphics'|'visb'|'dot'|'table'
local function visualize(kind, command, formulas)
  if not session or session.busy then
    return
  end
  local commands = vim.tbl_get(session.client.server_capabilities, 'executeCommandProvider', 'commands') or {}
  if not vim.tbl_contains(commands, 'prob.visualize') then
    vim.notify('prob: this b-language-server cannot visualise; update it (see :checkhealth prob)', vim.log.levels.ERROR)
    return
  end
  session.busy = true
  render()
  local args = {
    kind = kind,
    command = command or '',
    formulas = formulas or {},
    format = require('prob').config.visualization.format,
  }
  session.client:request('workspace/executeCommand', { command = 'prob.visualize', arguments = { args } }, function(err, result)
    if not session then
      return
    end
    session.busy = false
    local problem = err and err.message or (result and result.error)
    session.view = vim.tbl_extend('force', session.view or {}, { message = problem or '' })
    render()
    if problem or not result then
      return
    end
    session.last = result
    if result.path then
      open_file(result.path)
    elseif result.header then
      show_table(result)
    end
  end, session.source)
end

--- Asks for the formulas `v` takes, one after another, then shows it.
local function run_visualization(v)
  local formulas = {}
  local function ask()
    if #formulas >= (v.arity or 0) then
      return visualize(v.kind, v.command, formulas)
    end
    local prompt = v.arity > 1 and ('%s (formula %d of %d): '):format(label(v), #formulas + 1, v.arity) or (label(v) .. ': ')
    vim.ui.input({ prompt = prompt }, function(formula)
      if formula and formula ~= '' then
        table.insert(formulas, formula)
        ask()
      end
    end)
  end
  ask()
end

local function item_under_cursor()
  return session and session.items[vim.api.nvim_win_get_cursor(0)[1]]
end

--- Shows the source of `item` in the window of the model.
local function show_source(item)
  if not item or not item.uri or not item.line then
    return
  end
  local target
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if win ~= session.win then
      target = target or win
      if vim.api.nvim_win_get_buf(win) == vim.uri_to_bufnr(item.uri) then
        target = win
        break
      end
    end
  end
  if not target then
    return
  end
  vim.api.nvim_set_current_win(target)
  vim.cmd.edit(vim.fn.fnameescape(vim.uri_to_fname(item.uri)))
  vim.api.nvim_win_set_cursor(target, { item.line + 1, item.character or 0 })
  vim.cmd('normal! zz')
end

local function choose_event(callback)
  local item = item_under_cursor()
  if item and (item.kind == 'event' or item.kind == 'disabled') then
    return callback(item.event or item.name, item.parameters)
  end
  local names, seen = {}, {}
  for _, e in ipairs(vim.list_extend(vim.deepcopy(session.view.enabled or {}), session.view.disabled or {})) do
    local name = e.event or e.name
    if not seen[name] then
      seen[name] = true
      table.insert(names, name)
    end
  end
  vim.ui.select(names, { prompt = 'Event' }, function(name)
    if name then
      callback(name, '')
    end
  end)
end

local actions = {
  execute = function()
    local item = item_under_cursor()
    if not item then
      return
    end
    if item.kind == 'event' then
      request('execute', item.id)
    elseif item.kind == 'history' then
      request('goto', tostring(item.index))
    elseif item.kind == 'graphics' or item.kind == 'visb' then
      visualize(item.kind)
    elseif item.kind == 'visualizations' then
      session.expanded = not session.expanded
      render()
    elseif item.kind == 'visualization' then
      run_visualization(item)
    else
      show_source(item)
    end
  end,
  with = function()
    choose_event(function(event, parameters)
      vim.ui.input({ prompt = event .. ' with: ', default = (parameters or ''):gsub(', ', ' ∧ ') }, function(predicate)
        if predicate then
          request('executeWith', event .. '\0' .. predicate)
        end
      end)
    end)
  end,
  back = function()
    request('back', nil, vim.v.count1)
  end,
  forward = function()
    request('forward', nil, vim.v.count1)
  end,
  random = function()
    request('random', nil, vim.v.count1)
  end,
  find = function()
    vim.ui.input({ prompt = 'Find a state where: ' }, function(predicate)
      if predicate and predicate ~= '' then
        request('find', predicate)
      end
    end)
  end,
  check = function()
    request('modelCheck')
  end,
  visualize = function()
    local item = item_under_cursor()
    if item and item.kind == 'visualization' then
      return run_visualization(item)
    end
    local entries = vim.tbl_filter(function(v)
      return v.available
    end, session.view and session.view.visualizations or {})
    vim.ui.select(entries, {
      prompt = 'Visualise',
      format_item = function(v)
        return label(v) .. (v.arity > 0 and ' …' or '')
      end,
    }, function(v)
      if v then
        run_visualization(v)
      end
    end)
  end,
  graphics = function()
    local view = session.view or {}
    visualize((view.graphics == nil or #view.graphics == 0) and view.visb and 'visb' or 'graphics')
  end,
  source = function()
    show_source(item_under_cursor())
  end,
  restart = function()
    request('restart')
  end,
  help = function()
    session.help = not session.help
    render()
  end,
}

-- ---------------------------------------------------------------------------
-- The panel

local function open_panel()
  local buf, win = panel.open('ProB animation', 'probanimation', 46)

  local function map(lhs, action, desc)
    vim.keymap.set('n', lhs, actions[action], { buffer = buf, nowait = true, desc = 'ProB: ' .. desc })
  end
  map('<CR>', 'execute', 'execute event / go to step')
  map('p', 'with', 'execute event with predicate')
  map('u', 'back', 'step back')
  map('<C-r>', 'forward', 'step forward')
  map('r', 'random', 'random steps')
  map('f', 'find', 'find state')
  map('m', 'check', 'model check')
  map('v', 'visualize', 'visualise the state')
  map('I', 'graphics', 'open the graphical animation')
  map('gd', 'source', 'show source')
  map('R', 'restart', 'restart animation')
  map('?', 'help', 'toggle help')
  vim.keymap.set('n', 'q', M.stop, { buffer = buf, nowait = true, desc = 'ProB: stop animation' })

  vim.api.nvim_create_autocmd('BufWipeout', {
    buffer = buf,
    once = true,
    callback = function()
      vim.schedule(M.stop)
    end,
  })
  return buf, win
end

--- Animates the model in `bufnr` (default: the current buffer).
---@param bufnr? integer
function M.start(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  if session and vim.api.nvim_win_is_valid(session.win or -1) then
    if session.source == bufnr then
      vim.api.nvim_set_current_win(session.win)
      return
    end
    M.stop()
  end
  local client = vim.lsp.get_clients({ bufnr = bufnr, name = 'prob' })[1]
  if not client then
    vim.notify('prob: the B language server is not attached to this buffer', vim.log.levels.ERROR)
    return
  end
  local commands = vim.tbl_get(client.server_capabilities, 'executeCommandProvider', 'commands') or {}
  if not vim.tbl_contains(commands, 'prob.animate') then
    vim.notify(
      'prob: this b-language-server cannot animate; it is older than the plugin. Update it (see :checkhealth prob).',
      vim.log.levels.ERROR
    )
    return
  end
  if vim.bo[bufnr].modified then
    vim.notify('prob: ProB animates the file on disk; save it first', vim.log.levels.WARN)
  end

  session = { client = client, source = bufnr, items = {}, busy = false, stale = false, help = false, expanded = false }
  session.buf, session.win = open_panel()
  vim.api.nvim_create_autocmd('BufWritePost', {
    group = vim.api.nvim_create_augroup('prob_animation', { clear = true }),
    buffer = bufnr,
    callback = function()
      if session then
        session.stale = true
        render()
      end
    end,
  })
  request('start')
end

--- Stops the animation and closes its panel.
function M.stop()
  if not session then
    return
  end
  local current = session
  session = nil
  pcall(vim.api.nvim_del_augroup_by_name, 'prob_animation')
  current.client:request('workspace/executeCommand', { command = 'prob.animate', arguments = { { action = 'stop' } } }, function() end)
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
  end
  if current.win and vim.api.nvim_win_is_valid(current.win) then
    pcall(vim.api.nvim_win_close, current.win, true)
  end
end

--- The view of the running animation, for tests and statuslines.
function M.view()
  return session and session.view
end

--- Whether the animation is waiting for ProB.
function M.busy()
  return session ~= nil and session.busy
end

--- The result of the last visualisation, for tests.
function M.last_visualization()
  return session and session.last
end

--- Runs an action as if its key had been pressed in the panel.
---@param action string execute|with|back|forward|random|find|check|visualize|graphics|restart
function M.action(action, ...)
  if action == 'request' then
    return request(...)
  elseif action == 'visualize' and select('#', ...) > 0 then
    return visualize(...)
  end
  return actions[action]()
end

return M
