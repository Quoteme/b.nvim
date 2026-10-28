-- Runs the specs in tests/spec/: each one writes its files to a temporary
-- directory, opens them with the prob language server attached and compares
-- the reported problems with what the official documentation says.
--
-- Usage: nvim-prob -l tests/spec.lua [filter]

local done = false
vim.lsp.config('prob', {
  settings = { prob = { strictChecks = false } },
  handlers = {
    ['window/showMessage'] = function(_, result)
      if result.message:find('^Evaluation done') then
        done = true
      end
    end,
  },
})

local root = vim.fn.fnamemodify(debug.getinfo(1, 'S').source:sub(2), ':p:h') .. '/spec/'
local filter = _G.arg and _G.arg[1] or ''

local function await(what)
  if not vim.wait(120000, function() return done end, 50) then
    error('timed out waiting for ' .. what)
  end
end

local function problems(dir)
  local lines = {}
  for _, d in ipairs(vim.diagnostic.get()) do
    if d.severity ~= vim.diagnostic.severity.HINT and vim.api.nvim_buf_get_name(d.bufnr):find(dir, 1, true) then
      local name = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(d.bufnr), ':t')
      table.insert(lines, ('%s:%d: %s'):format(name, d.lnum + 1, d.message:gsub('\n', ' ')))
    end
  end
  return lines
end

local function quickfix()
  local lines = {}
  for _, item in ipairs(vim.fn.getqflist()) do
    local name = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(item.bufnr), ':t')
    table.insert(lines, ('%s:%d: %s'):format(name, item.lnum, item.text))
  end
  return lines
end

-- Every expected entry must match one actual line by prefix and substring,
-- and no actual line may be left over.
local function compare(expected, actual)
  local rest = vim.deepcopy(actual)
  local missing = {}
  for _, want in ipairs(expected) do
    local location, text = want:match('^(.-:%d+: )(.*)$')
    local found
    for i, line in ipairs(rest) do
      if vim.startswith(line, location) and line:find(text, #location + 1, true) then
        found = i
        break
      end
    end
    if found then
      table.remove(rest, found)
    else
      table.insert(missing, want)
    end
  end
  return missing, rest
end

local animation = require('prob.animate')

--- Sends one animation request and waits for the new view.
local function animation_step(action, argument, count)
  local before = animation.view()
  animation.action('request', action, argument, count)
  if not vim.wait(120000, function() return not animation.busy() and animation.view() ~= before end, 50) then
    error('timed out waiting for ' .. action)
  end
  return animation.view()
end

--- Runs the steps of an animation spec and compares the resulting view.
local function animate(spec)
  animation.start()
  vim.wait(120000, function() return animation.view() ~= nil and not animation.busy() end, 50)
  local view = animation.view()
  for _, step in ipairs(spec.steps) do
    if type(step) == 'string' then
      local transition
      for _, e in ipairs(view.enabled or {}) do
        if e.name == step then
          transition = transition or e
        end
      end
      if not transition then
        animation.stop()
        return { ('%s is not enabled'):format(step) }
      end
      view = animation_step('execute', transition.id)
    elseif step.with then
      view = animation_step('executeWith', step.with[1] .. '\0' .. step.with[2])
    else
      local action, argument = next(step)
      local count = type(argument) == 'number' and argument or 1
      view = animation_step(action, type(argument) == 'string' and argument or tostring(count), count)
    end
  end

  local errors = {}
  local function check(what, expected, actual)
    if not vim.deep_equal(expected, actual) then
      table.insert(errors, ('%s: expected %s, got %s'):format(what, vim.inspect(expected), vim.inspect(actual)))
    end
  end
  for _, kind in ipairs({ 'variables', 'constants' }) do
    if spec[kind] then
      local actual = {}
      for _, entry in ipairs(view[kind] or {}) do
        if spec[kind][entry.name] then
          actual[entry.name] = entry.value
        end
      end
      check(kind, spec[kind], actual)
    end
  end
  if spec.enabled then
    -- "add: k = 1" compares the parameters too, a plain "add" only the name.
    local names = vim.tbl_map(function(e)
      local detailed = e.parameters ~= '' and (e.name .. ': ' .. e.parameters)
      return detailed and vim.tbl_contains(spec.enabled, detailed) and detailed or e.name
    end, view.enabled or {})
    table.sort(names)
    local expected = vim.deepcopy(spec.enabled)
    table.sort(expected)
    check('enabled', expected, names)
  end
  if spec.changed then
    local changed = {}
    for _, v in ipairs(view.variables or {}) do
      if v.changed then
        table.insert(changed, v.name)
      end
    end
    table.sort(changed)
    check('changed', spec.changed, changed)
  end
  if spec.invariants then
    local actual = {}
    for _, inv in ipairs(view.invariants or {}) do
      actual[inv.label] = inv.ok
    end
    check('invariants', spec.invariants, actual)
  end
  if spec.step then
    check('step', spec.step, view.step)
  end
  if spec.deadlock ~= nil then
    check('deadlock', spec.deadlock, view.deadlock)
  end
  if spec.history then
    check('history', spec.history, vim.tbl_map(function(h) return h.label end, vim.tbl_filter(function(h) return not h.future end, view.history or {})))
  end
  if spec.message and not (view.message or ''):find(spec.message, 1, true) then
    table.insert(errors, ('message: expected %q in %q'):format(spec.message, view.message or ''))
  end
  animation.stop()
  return errors
end

local function run(spec)
  if spec.typed then
    local text = require('prob.keyboard').translate(spec.typed)
    return text == spec.text and {} or { ('typed %q, got %q, expected %q'):format(spec.typed, text, spec.text) }
  end
  local dir = vim.fn.tempname()
  vim.fn.mkdir(dir, 'p')
  local open = spec.open
  for name, text in pairs(spec.files) do
    vim.fn.writefile(vim.split(text, '\n', { plain = true }), dir .. '/' .. name)
    open = open or name
  end

  done = false
  vim.cmd.edit(vim.fn.fnameescape(dir .. '/' .. open))
  await('the language server')

  if spec.action then
    done = false
    vim.fn.setqflist({}, 'r')
    vim.lsp.buf.code_action({
      apply = true,
      filter = function(action)
        local command = type(action.command) == 'table' and action.command.command or action.command
        return command == spec.action
      end,
    })
    if spec.quickfix then
      vim.wait(120000, function() return #vim.fn.getqflist() > 0 end, 50)
    else
      await(spec.action)
    end
  end

  if spec.steps then
    return animate(spec)
  end

  local errors = {}
  local missing, extra = compare(spec.expect, problems(dir))
  vim.list_extend(errors, vim.tbl_map(function(l) return 'missing: ' .. l end, missing))
  vim.list_extend(errors, vim.tbl_map(function(l) return 'unexpected: ' .. l end, extra))

  if spec.quickfix then
    missing = compare(spec.quickfix, quickfix())
    vim.list_extend(errors, vim.tbl_map(function(l) return 'missing in quickfix: ' .. l end, missing))
  end

  for name, text in pairs(spec.files) do
    local lang = text:match('^%s*(%l+)') and 'eventb' or 'b'
    local broken = vim.treesitter.get_string_parser(text, lang):parse()[1]:root():has_error()
    if broken ~= (spec.syntax_error or false) then
      table.insert(errors, (broken and 'tree-sitter error in ' or 'no tree-sitter error in ') .. name)
    end
  end

  vim.diagnostic.reset()
  vim.cmd('silent! %bwipeout!')
  vim.fn.delete(dir, 'rf')
  return errors
end

local failed = 0
local names = vim.fn.globpath(root, '**/*.lua', false, true)
table.sort(names)
for _, path in ipairs(names) do
  local name = path:sub(#root + 1, -5)
  if name:find(filter, 1, true) then
    local ok, errors = pcall(run, dofile(path))
    if not ok then
      errors = { errors }
    end
    print(('%s %s'):format(#errors == 0 and 'PASS' or 'FAIL', name))
    for _, e in ipairs(errors) do
      print('  ' .. e)
    end
    if #errors > 0 then
      failed = failed + 1
    end
  end
end

print(failed == 0 and 'all specs passed' or ('%d spec(s) failed'):format(failed))
vim.cmd(failed == 0 and 'qall!' or 'cquit!')
