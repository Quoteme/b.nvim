-- Proves proof obligations interactively, like Rodin's Proving perspective: a
-- side panel shows the proof tree, the hypotheses and the goal of the current
-- node, with the operators that tactics apply to marked as Rodin marks them in
-- red. Like Lean's infoview, the panel follows the cursor to the obligation
-- under it. Proofs are saved in Rodin's .bpr files next to the model.
local M = {}

local panel = require('prob.panel')
local line, put, pad = panel.line, panel.put, panel.pad

local panel_ns = vim.api.nvim_create_namespace('prob_proof_panel')

---@class prob.Proof
---@field client vim.lsp.Client
---@field source integer buffer of the model
---@field buf? integer panel buffer
---@field win? integer panel window
---@field view? table last view sent by the server
---@field items table<integer, table> panel line → item under it
---@field busy boolean
---@field stale boolean the model was saved since the obligation was opened
---@field help boolean
---@field all boolean show the hypotheses that are not selected
---@field follow boolean switch to the obligation under the cursor in the model
local session

local highlights = {
  ProbProofTitle = 'Title',
  ProbProofSection = 'Statement',
  ProbProofOpen = 'DiagnosticWarn',
  ProbProofClosed = 'DiagnosticOk',
  ProbProofBroken = 'DiagnosticError',
  ProbProofCurrent = 'Special',
  ProbProofRule = 'Function',
  ProbProofOrigin = 'Identifier',
  ProbProofHidden = 'Comment',
  ProbProofOperator = 'DiagnosticError',
  ProbProofTurnstile = 'Special',
  ProbProofMessage = 'WarningMsg',
  ProbProofHelp = 'Comment',
  ProbProofKey = 'Special',
}
for group, link in pairs(highlights) do
  vim.api.nvim_set_hl(0, group, { link = link, default = true })
end

local keys = {
  { '<CR>', 'tree: go to the node · hypothesis/goal: tactics (at the operator under the cursor)' },
  { 'p', 'prove the current node with ProB' },
  { 'a', 'prove all open goals with ProB' },
  { 't', 'type a tactic: ah P, dc P, ct, exI e, allD e, …' },
  { 's', 'select or deselect the hypothesis' },
  { 'H', 'show all hypotheses, or only the selected ones' },
  { 'x', 'prune the tree at the node' },
  { 'u', 'undo' },
  { '<C-r>', 'redo' },
  { ']g', 'next open goal' },
  { '[g', 'previous open goal' },
  { 'r', 'review: accept the node without proof' },
  { 'o', 'open another proof obligation' },
  { 'f', 'follow the cursor in the model (on/off)' },
  { 'gd', 'show where the hypothesis or goal comes from' },
  { 'q', 'close' },
  { '?', 'toggle this help' },
}

local marks = {
  discharged = '✓',
  proved = '✓✎',
  reviewed = '≈',
  disproved = '✗',
  undischarged = '?',
  broken = '⚠',
}

-- ---------------------------------------------------------------------------
-- Rendering

--- Appends a predicate, marking the operators tactics apply to.
local function put_predicate(l, pred, group)
  local offset = #l.text
  put(l, pred.text, group)
  for _, op in ipairs(pred.operators or {}) do
    local from = vim.str_byteindex(pred.text, 'utf-16', op.start, false)
    local to = vim.str_byteindex(pred.text, 'utf-16', op['end'], false)
    table.insert(l.marks, { offset + from, offset + to, 'ProbProofOperator' })
  end
  return offset
end

local function render_lines(view)
  local lines = {}
  local function add(l)
    table.insert(lines, l)
  end
  local function section(title, note)
    add(line())
    local l = put(line(), ' ' .. title, 'ProbProofSection')
    if note then
      put(l, '  ' .. note, 'ProbProofHelp')
    end
    add(l)
  end

  local title = put(line(), ' ◆ Proof', 'ProbProofTitle')
  if view.name then
    put(title, ' · ' .. view.name, 'ProbProofTitle')
    put(
      title,
      '  ' .. (marks[view.status] or '') .. ' ' .. (view.status or ''),
      view.complete and 'ProbProofClosed' or 'ProbProofHelp'
    )
  end
  if session.busy then
    put(title, '  …', 'ProbProofMessage')
  end
  add(title)
  if session.stale then
    add(put(line(), ' model changed · o reopens the obligation', 'ProbProofMessage'))
  end
  if view.message and view.message ~= '' then
    add(put(line(), ' ' .. view.message, 'ProbProofMessage'))
  end
  if view.error then
    add(put(line(), ' ' .. view.error, 'ProbProofBroken'))
    return lines
  end

  local open = 0
  for _, n in ipairs(view.tree or {}) do
    if n.open then
      open = open + 1
    end
  end
  section('TREE', open == 0 and 'proved' or (open == 1 and '1 open goal' or open .. ' open goals'))
  for _, n in ipairs(view.tree or {}) do
    local l = line({ kind = 'node', path = n.path })
    put(l, n.current and ' ▸ ' or '   ', 'ProbProofCurrent')
    put(l, string.rep('  ', n.depth))
    if n.broken then
      put(l, '⚠ ', 'ProbProofBroken')
    elseif n.open then
      put(l, '○ ', 'ProbProofOpen')
    else
      put(l, n.closed and '✓ ' or '◐ ', n.closed and 'ProbProofClosed' or 'ProbProofOpen')
    end
    put(l, n.display, n.open and 'ProbProofHelp' or 'ProbProofRule')
    add(l)
  end

  local hyps = view.hyps or {}
  local shown, hidden = {}, 0
  for _, h in ipairs(hyps) do
    if session.all or h.state == 'selected' then
      table.insert(shown, h)
    else
      hidden = hidden + 1
    end
  end
  section(
    'HYPOTHESES',
    hidden > 0 and ('%d more · H shows them'):format(hidden) or (session.all and 'H: selected only' or nil)
  )
  local width = 4
  for _, h in ipairs(shown) do
    width = math.max(width, vim.fn.strdisplaywidth(h.origin or '') + 2)
  end
  for _, h in ipairs(shown) do
    local l = put(line({ kind = 'hyp', pred = h }), '   ')
    put(l, pad(h.origin or '', width), 'ProbProofOrigin')
    l.item.offset = put_predicate(l, h, h.state == 'selected' and nil or 'ProbProofHidden')
    add(l)
  end

  section('GOAL')
  if view.goal then
    local l = line({ kind = 'goal', pred = view.goal })
    put(l, '   ⊢ ', 'ProbProofTurnstile')
    l.item.offset = put_predicate(l, view.goal, nil)
    add(l)
  end

  add(line())
  if session.help then
    for _, k in ipairs(keys) do
      local l = put(line(), ' ' .. pad(k[1], 7), 'ProbProofKey')
      put(l, k[2], 'ProbProofHelp')
      add(l)
    end
  else
    local l = line()
    for i, k in ipairs({ { '⏎', 'tactics' }, { 'p', 'ProB' }, { 't', 'type' }, { 'u', 'undo' }, { '?', 'help' } }) do
      put(l, (i == 1 and ' ' or ' · ') .. k[1], 'ProbProofKey')
      put(l, ' ' .. k[2], 'ProbProofHelp')
    end
    add(l)
  end
  return lines
end

local function render()
  if not session or not session.buf or not vim.api.nvim_buf_is_valid(session.buf) then
    return
  end
  session.items = panel.draw(session.buf, panel_ns, render_lines(session.view or {}))
end

-- ---------------------------------------------------------------------------
-- Talking to the server

--- Sends one proof action and shows the resulting view.
---@param args table action and its arguments
---@param callback? fun(result: table?)
local function request(args, callback)
  if not session or session.busy then
    return
  end
  session.busy = true
  render()
  args.uri = args.uri or vim.uri_from_bufnr(session.source)
  session.client:request(
    'workspace/executeCommand',
    { command = 'prob.prove', arguments = { args } },
    function(err, result)
      if not session then
        return
      end
      session.busy = false
      if err then
        session.view = vim.tbl_extend('force', session.view or {}, { message = err.message })
      elseif result then
        session.view = result
        if args.action == 'open' then
          session.stale = false
        end
      end
      render()
      if callback then
        callback(result)
      end
    end,
    session.source
  )
end

local function open_obligation(name)
  request({ action = 'open', name = name })
end

local function item_under_cursor()
  return session and session.items[vim.api.nvim_win_get_cursor(0)[1]]
end

--- The tactics at the operator under the cursor, or else those for the whole predicate.
local function tactics_at_cursor(item)
  local col = vim.api.nvim_win_get_cursor(0)[2] - item.offset
  local text = item.pred.text
  for _, op in ipairs(item.pred.operators or {}) do
    local from = vim.str_byteindex(text, 'utf-16', op.start, false)
    local to = vim.str_byteindex(text, 'utf-16', op['end'], false)
    if col >= from and col < to then
      return op.tactics
    end
  end
  return item.pred.tactics or {}
end

--- Applies `tactic` to the hypothesis or goal of `item`, asking for its input if it needs one.
local function apply(tactic, item, input)
  local args = {
    action = 'apply',
    tactic = tactic.name,
    hyp = item and item.kind == 'hyp' and item.pred.id or nil,
    position = tactic.position,
    input = input,
  }
  if tactic.input and not input then
    vim.ui.input({ prompt = tactic.label .. ' (' .. tactic.input .. '): ' }, function(text)
      if text and text ~= '' then
        args.input = require('prob.keyboard').translate(text)
        request(args)
      end
    end)
    return
  end
  request(args)
end

--- Moves to the next (`step` 1) or previous (-1) open goal of the tree.
local function goto_open(step)
  local tree = session.view and session.view.tree or {}
  local current = 1
  for i, n in ipairs(tree) do
    if n.current then
      current = i
    end
  end
  for k = 1, #tree do
    local n = tree[(current - 1 + step * k) % #tree + 1]
    if n.open then
      return request({ action = 'goto', node = n.path })
    end
  end
end

--- Shows the line of the model a hypothesis or the goal comes from.
local function show_origin(item)
  local win = vim.fn.bufwinid(session.source)
  if win == -1 then
    return
  end
  local row
  if item and item.kind == 'hyp' and item.pred.origin then
    local pattern = '@' .. item.pred.origin:gsub('%p', '%%%0') .. "%f[^%w_'.]"
    for i, text in ipairs(vim.api.nvim_buf_get_lines(session.source, 0, -1, false)) do
      if text:find(pattern) then
        row = i
        break
      end
    end
  elseif session.view and session.view.line then
    row = session.view.line + 1
  end
  if row then
    vim.api.nvim_set_current_win(win)
    vim.api.nvim_win_set_cursor(win, { row, 0 })
    vim.cmd('normal! zz')
  end
end

local actions = {
  execute = function()
    local item = item_under_cursor()
    if not item then
      return
    end
    if item.kind == 'node' then
      return request({ action = 'goto', node = item.path })
    end
    if item.kind ~= 'hyp' and item.kind ~= 'goal' then
      return
    end
    -- Only the selection changes that change something.
    local useless = {
      selected = { select = true, show = true },
      visible = { deselect = true, show = true },
      hidden = { hide = true, select = true, deselect = true },
    }
    local tactics = vim.tbl_filter(function(t)
      return not (useless[item.pred.state or ''] or {})[t.name]
    end, vim.deepcopy(tactics_at_cursor(item)))
    if item.kind == 'goal' then
      table.insert(tactics, { name = 'prob', label = 'ProB: prove with ProB' })
      table.insert(tactics, { name = 'review', label = 'review: accept without proof' })
    end
    if #tactics == 0 then
      return vim.notify('prob: no tactic applies here', vim.log.levels.INFO)
    end
    vim.ui.select(tactics, {
      prompt = item.kind == 'goal' and 'Goal' or 'Hypothesis',
      format_item = function(t)
        return t.label .. (t.input and ' …' or '')
      end,
    }, function(tactic)
      if not tactic then
        return
      elseif tactic.name == 'prob' or tactic.name == 'review' then
        request({ action = tactic.name })
      else
        apply(tactic, item)
      end
    end)
  end,
  prob = function()
    request({ action = 'prob' })
  end,
  proball = function()
    request({ action = 'proball' })
  end,
  type = function()
    local item = item_under_cursor()
    vim.ui.input({ prompt = 'Tactic: ' }, function(text)
      if not text or text == '' then
        return
      end
      local name, input = text:match('^%s*(%S+)%s*(.-)%s*$')
      local aliases = { inst = 'allD', ae = 'exI', mp = 'impE', ['⇒'] = 'impI', ['∀'] = 'allI', ['∧'] = 'conj' }
      name = aliases[name] or name
      if name == 'prob' or name == 'review' then
        return request({ action = name })
      end
      request({
        action = 'apply',
        tactic = name,
        hyp = item and item.kind == 'hyp' and item.pred.id or nil,
        input = input ~= '' and require('prob.keyboard').translate(input) or nil,
      })
    end)
  end,
  select = function()
    local item = item_under_cursor()
    if item and item.kind == 'hyp' then
      apply({ name = item.pred.state == 'selected' and 'deselect' or 'select' }, item)
    end
  end,
  all = function()
    session.all = not session.all
    render()
  end,
  prune = function()
    local item = item_under_cursor()
    request({ action = 'prune', node = item and item.kind == 'node' and item.path or nil })
  end,
  undo = function()
    request({ action = 'undo' })
  end,
  redo = function()
    request({ action = 'redo' })
  end,
  next = function()
    goto_open(1)
  end,
  previous = function()
    goto_open(-1)
  end,
  review = function()
    request({ action = 'review' })
  end,
  obligations = function()
    local obligations = session.view and session.view.obligations or {}
    vim.ui.select(obligations, {
      prompt = 'Proof obligation',
      format_item = function(o)
        return (marks[o.status] or ' ') .. ' ' .. o.name
      end,
    }, function(o)
      if o then
        open_obligation(o.name)
      end
    end)
  end,
  follow = function()
    session.follow = not session.follow
    vim.notify('prob: the proof panel ' .. (session.follow and 'follows' or 'no longer follows') .. ' the cursor')
  end,
  origin = function()
    show_origin(item_under_cursor())
  end,
  help = function()
    session.help = not session.help
    render()
  end,
}

-- ---------------------------------------------------------------------------
-- Following the cursor in the model, as Lean's infoview does

local follow_timer

--- Opens the obligation at the cursor in the model, unless a proof is under way.
local function follow()
  if not session or not session.follow or session.busy or vim.api.nvim_get_current_buf() ~= session.source then
    return
  end
  local row = vim.api.nvim_win_get_cursor(0)[1] - 1
  if session.row == row then
    return
  end
  session.row = row
  session.client:request('workspace/executeCommand', {
    command = 'prob.prove',
    arguments = { { action = 'at', uri = vim.uri_from_bufnr(session.source), line = row } },
  }, function(_, result)
    local view = session and session.view
    if not view or not result or not result.name or result.name == view.name then
      return
    end
    -- Leave a proof under way, with open goals left, alone.
    local started = view.tree and #view.tree > 1
    if started and not view.complete then
      return
    end
    open_obligation(result.name)
  end, session.source)
end

local function on_cursor_moved()
  if follow_timer then
    follow_timer:stop()
  end
  follow_timer = vim.defer_fn(follow, 150)
end

-- ---------------------------------------------------------------------------
-- The panel

local function open_panel()
  local buf, win = panel.open('ProB proof', 'probproof', 56)
  local function map(lhs, action, desc)
    vim.keymap.set('n', lhs, actions[action], { buffer = buf, nowait = true, desc = 'ProB: ' .. desc })
  end
  map('<CR>', 'execute', 'tactics / go to node')
  map('p', 'prob', 'prove with ProB')
  map('a', 'proball', 'prove all open goals with ProB')
  map('t', 'type', 'type a tactic')
  map('s', 'select', 'select or deselect hypothesis')
  map('H', 'all', 'show all hypotheses')
  map('x', 'prune', 'prune')
  map('u', 'undo', 'undo')
  map('<C-r>', 'redo', 'redo')
  map(']g', 'next', 'next open goal')
  map('[g', 'previous', 'previous open goal')
  map('r', 'review', 'review')
  map('o', 'obligations', 'open proof obligation')
  map('f', 'follow', 'follow the cursor')
  map('gd', 'origin', 'show origin')
  map('?', 'help', 'toggle help')
  vim.keymap.set('n', 'q', M.stop, { buffer = buf, nowait = true, desc = 'ProB: close proof' })

  vim.api.nvim_create_autocmd('BufWipeout', {
    buffer = buf,
    once = true,
    callback = function()
      vim.schedule(M.stop)
    end,
  })
  return buf, win
end

--- Proves an obligation of the model in `bufnr` (default: the current buffer):
--- `name`, or the one at the cursor, or the first one not proved yet.
---@param name? string
---@param bufnr? integer
function M.start(name, bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local client = vim.lsp.get_clients({ bufnr = bufnr, name = 'prob' })[1]
  if not client then
    vim.notify('prob: the B language server is not attached to this buffer', vim.log.levels.ERROR)
    return
  end
  local commands = vim.tbl_get(client.server_capabilities, 'executeCommandProvider', 'commands') or {}
  if not vim.tbl_contains(commands, 'prob.prove') then
    vim.notify(
      'prob: this b-language-server cannot prove interactively; it is older than the plugin. Update it (see :checkhealth prob).',
      vim.log.levels.ERROR
    )
    return
  end
  if vim.bo[bufnr].modified then
    vim.notify('prob: the proof obligations are those of the file on disk; save it first', vim.log.levels.WARN)
  end

  local row = vim.api.nvim_get_current_buf() == bufnr and vim.api.nvim_win_get_cursor(0)[1] - 1 or nil
  if session and session.source == bufnr and vim.api.nvim_win_is_valid(session.win or -1) then
    vim.api.nvim_set_current_win(session.win)
  else
    M.stop()
    session = {
      client = client,
      source = bufnr,
      items = {},
      busy = false,
      stale = false,
      help = false,
      all = false,
      follow = true,
    }
    session.buf, session.win = open_panel()
    local group = vim.api.nvim_create_augroup('prob_proof', { clear = true })
    vim.api.nvim_create_autocmd('BufWritePost', {
      group = group,
      buffer = bufnr,
      callback = function()
        if session then
          session.stale = true
          render()
        end
      end,
    })
    vim.api.nvim_create_autocmd('CursorMoved', { group = group, buffer = bufnr, callback = on_cursor_moved })
  end

  if name or not row then
    return open_obligation(name)
  end
  -- Without a name, the obligation at the cursor, if there is one.
  client:request('workspace/executeCommand', {
    command = 'prob.prove',
    arguments = { { action = 'at', uri = vim.uri_from_bufnr(bufnr), line = row } },
  }, function(_, result)
    if session then
      session.row = row
      open_obligation(result and result.name or nil)
    end
  end, bufnr)
end

--- Closes the proof panel.
function M.stop()
  if not session then
    return
  end
  local current = session
  session = nil
  pcall(vim.api.nvim_del_augroup_by_name, 'prob_proof')
  current.client:request(
    'workspace/executeCommand',
    { command = 'prob.prove', arguments = { { action = 'close' } } },
    function() end
  )
  if current.win and vim.api.nvim_win_is_valid(current.win) then
    pcall(vim.api.nvim_win_close, current.win, true)
  end
end

--- The proof obligations of the model in `bufnr`, for completing `:ProbProve`.
---@return string[]
function M.names(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local client = vim.lsp.get_clients({ bufnr = bufnr, name = 'prob' })[1]
  if not client then
    return {}
  end
  local response = client:request_sync('workspace/executeCommand', {
    command = 'prob.showPOs',
    arguments = { vim.uri_from_bufnr(bufnr) },
  }, 2000, bufnr)
  return vim.tbl_map(function(po)
    return po.name
  end, response and response.result or {})
end

--- The view of the open proof, for tests and statuslines.
function M.view()
  return session and session.view
end

--- Whether the panel is waiting for the server.
function M.busy()
  return session ~= nil and session.busy
end

--- Runs an action as if its key had been pressed in the panel, or sends a
--- request (`M.action('request', { action = 'apply', … })`).
function M.action(action, ...)
  if action == 'request' then
    return request(...)
  end
  return actions[action]()
end

return M
