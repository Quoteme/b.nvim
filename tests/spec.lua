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
-- Rendered graphs are checked, not opened in a viewer.
require('prob').config.visualization.open = function() end

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
  if spec.graphics then
    local rows = vim.tbl_map(function(row)
      return table.concat(vim.tbl_map(function(cell) return cell.text end, row), ' ')
    end, view.graphics or {})
    check('graphics', spec.graphics, rows)
  end
  if spec.visb ~= nil then
    check('visb', spec.visb, view.visb)
  end
  if spec.images ~= nil then
    local images = false
    for _, row in ipairs(view.graphics or {}) do
      for _, cell in ipairs(row) do
        images = images or cell.image ~= nil
      end
    end
    check('images', spec.images, images)
  end
  for _, v in ipairs(spec.visualize or {}) do
    local before = animation.last_visualization()
    animation.action('visualize', v[1], v[2], v[3])
    vim.wait(120000, function() return not animation.busy() and (animation.last_visualization() ~= before or (animation.view().message or '') ~= '') end, 50)
    local result = animation.last_visualization()
    if result == before then
      table.insert(errors, ('%s: %s'):format(v[2], animation.view().message or 'no result'))
    elseif v.contains then
      local text = table.concat(vim.fn.readfile(result.path or ''), '\n')
      if not text:find(v.contains, 1, true) then
        table.insert(errors, ('%s: no %q in %s'):format(v[2] or v[1], v.contains, result.path or '?'))
      end
    else
      check(v[2], { v.header, v.rows }, { result.header, result.rows })
    end
  end
  if spec.message and not (view.message or ''):find(spec.message, 1, true) then
    table.insert(errors, ('message: expected %q in %q'):format(spec.message, view.message or ''))
  end
  animation.stop()
  return errors
end

local proof = require('prob.prove')

--- Sends one request to the proof panel and waits for the new view.
local function proof_request(args)
  local before = proof.view()
  proof.action('request', args)
  if not vim.wait(120000, function() return not proof.busy() and proof.view() ~= before end, 50) then
    error('timed out waiting for ' .. args.action)
  end
  return proof.view()
end

local function open_proof(name)
  proof.start(name)
  if not vim.wait(120000, function() return proof.view() ~= nil and not proof.busy() end, 50) then
    error('timed out opening ' .. name)
  end
  return proof.view()
end

--- Compares the open proof with what a proof spec expects.
local function check_proof(view, expected, errors, what)
  local function fail(text)
    table.insert(errors, what .. text)
  end
  if expected.status and view.status ~= expected.status then
    fail(('status: expected %s, got %s'):format(expected.status, tostring(view.status)))
  end
  if expected.remaining then
    local open = #vim.tbl_filter(function(n) return n.open end, view.tree or {})
    if open ~= expected.remaining then
      fail(('open goals: expected %d, got %d'):format(expected.remaining, open))
    end
  end
  if expected.broken then
    local broken = #vim.tbl_filter(function(n) return n.broken end, view.tree or {})
    if broken ~= expected.broken then
      fail(('broken nodes: expected %d, got %d'):format(expected.broken, broken))
    end
  end
  local displays = vim.tbl_map(function(n) return n.display end, view.tree or {})
  for _, want in ipairs(expected.nodes or {}) do
    if not vim.tbl_contains(displays, want) then
      fail(('no node %q in the tree: %s'):format(want, table.concat(displays, ' | ')))
    end
  end
  if expected.goal and (view.goal or {}).text ~= expected.goal then
    fail(('goal: expected %s, got %s'):format(expected.goal, (view.goal or {}).text))
  end
  for _, want in ipairs(expected.hyps or {}) do
    local found = vim.tbl_filter(function(h) return h.text == want end, view.hyps or {})
    if #found == 0 then
      fail(('no hypothesis %s among %s'):format(want, table.concat(vim.tbl_map(function(h) return h.text end, view.hyps or {}), ', ')))
    end
  end
  if expected.message and not (view.message or ''):find(expected.message, 1, true) then
    fail(('message: expected %q in %q'):format(expected.message, view.message or ''))
  end
end

--- Runs the tactics of a proof spec on its obligation and checks the proof and its .bpr file.
--- Each step is a tactic, `{ 'allD', hyp = '∀x', input = '1' }`, at the hypothesis `hyp`, or the
--- first containing it (else the goal), and at the sub-formula whose menu entry contains `where`, or an
--- action, `{ action = 'prob' }`.
local function prove(spec, dir)
  local view = open_proof(spec.prove)
  if view.error then
    return { view.error }
  end
  local errors = {}
  if view.name ~= spec.prove then
    return { ('opened %s, not %s'):format(tostring(view.name), spec.prove) }
  end
  for _, step in ipairs(spec.tactics or {}) do
    if step.action then
      view = proof_request(vim.deepcopy(step))
    else
      local pred, hyp = view.goal, nil
      if step.hyp then
        -- The hypothesis written exactly, else the first one containing the text.
        for _, h in ipairs(view.hyps or {}) do
          if h.text == step.hyp or (not hyp and h.text:find(step.hyp, 1, true)) then
            pred, hyp = h, h.id
          end
        end
        if not hyp then
          return { ('%s: no hypothesis containing %s'):format(step[1], step.hyp) }
        end
      end
      local position
      for _, t in ipairs(pred.tactics or {}) do
        if t.name == step[1] and (not step.where or t.label:find(step.where, 1, true)) then
          position = t.position
          break
        end
      end
      view = proof_request({ action = 'apply', tactic = step[1], hyp = hyp, position = position, input = step.input })
      if (view.message or '') ~= '' and not step.fails then
        return { ('%s: %s'):format(step[1], view.message) }
      end
    end
  end
  check_proof(view, spec, errors, '')

  local bpr = table.concat(vim.fn.readfile(dir .. '/' .. vim.fn.fnamemodify(spec.open or next(spec.files), ':r') .. '.bpr'), '\n')
  for _, want in ipairs(spec.bpr or {}) do
    if not bpr:find(want, 1, true) then
      table.insert(errors, ('.bpr lacks %q'):format(want))
    end
  end

  -- Saving the model checks it again, replaying the saved proof.
  if spec.after then
    proof.stop()
    local source = vim.fn.bufnr(dir .. '/' .. (spec.open or next(spec.files)))
    vim.api.nvim_set_current_buf(source)
    if spec.after.replace then
      local text = table.concat(vim.api.nvim_buf_get_lines(source, 0, -1, false), '\n')
      text = text:gsub(vim.pesc(spec.after.replace[1]), (spec.after.replace[2]:gsub('%%', '%%%%')))
      vim.api.nvim_buf_set_lines(source, 0, -1, false, vim.split(text, '\n', { plain = true }))
    end
    done = false
    vim.cmd('silent write')
    await('the language server')
    local missing, extra = compare(spec.after.expect or {}, problems(dir))
    vim.list_extend(errors, vim.tbl_map(function(l) return 'after saving, missing: ' .. l end, missing))
    vim.list_extend(errors, vim.tbl_map(function(l) return 'after saving, unexpected: ' .. l end, extra))
    check_proof(open_proof(spec.prove), spec.after, errors, 'after saving, ')
  end
  proof.stop()
  return errors
end

--- The examples of the hover documentation in `language` that must be true.
local function examples(language)
  local path = vim.fs.dirname(vim.fs.dirname(vim.fs.normalize(root))) .. '/nix/b-language-server/hover/examples.tsv'
  local result = {}
  for _, line in ipairs(vim.fn.readfile(path)) do
    local fields = vim.split(line, '\t', { plain = true })
    if fields[1] == language and fields[3] == 'pred' then
      table.insert(result, { title = fields[2], text = fields[4] })
    end
  end
  return result
end

--- Checks that every Event-B example is a theorem ProB proves, as part of a context.
local function check_eventb_examples()
  local lines = { 'context examples', 'axioms' }
  for i, example in ipairs(examples('eventb')) do
    table.insert(lines, ('  theorem @ex%d %s'):format(i, example.text))
  end
  table.insert(lines, 'end')
  local dir = vim.fn.tempname()
  vim.fn.mkdir(dir, 'p')
  vim.fn.writefile(lines, dir .. '/examples.mch')
  done = false
  vim.cmd.edit(vim.fn.fnameescape(dir .. '/examples.mch'))
  await('the language server')
  local errors = vim.tbl_map(function(d) return 'example: ' .. d.message end, vim.diagnostic.get(0, { severity = { min = vim.diagnostic.severity.WARN } }))
  vim.fn.setqflist({}, 'r')
  vim.lsp.buf.code_action({ apply = true, filter = function(a) return (type(a.command) == 'table' and a.command.command or a.command) == 'prob.showPOs' end })
  vim.wait(120000, function() return #vim.fn.getqflist() > 0 end, 50)
  local list = examples('eventb')
  for _, item in ipairs(vim.fn.getqflist()) do
    if not item.text:find(': discharged', 1, true) then
      local index = tonumber(item.text:match('^ex(%d+)/'))
      table.insert(errors, ('%s (%s)'):format(item.text, index and list[index].text or '?'))
    end
  end
  vim.cmd('silent! %bwipeout!')
  return errors
end

--- Checks that ProB evaluates every classical B example to TRUE.
local function check_b_examples()
  local list = examples('b')
  local errors = {}
  for _, example in ipairs(list) do
    local output = vim.fn.system({ 'probcli', '-repl' }, example.text .. '\n')
    output = output:gsub('\27%[[0-9;]*m', '')
    if not output:find('is TRUE') then
      table.insert(errors, ('%s: %s'):format(example.title, example.text))
    end
  end
  return errors
end

local function run(spec)
  if spec.examples == 'eventb' then
    return check_eventb_examples()
  elseif spec.examples == 'b' then
    return check_b_examples()
  end
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
  if spec.prove then
    local errors = prove(spec, dir)
    vim.diagnostic.reset()
    vim.cmd('silent! %bwipeout!')
    vim.fn.delete(dir, 'rf')
    return errors
  end
  if spec.hover then
    local client = vim.lsp.get_clients({ bufnr = 0, name = 'prob' })[1]
    local response = client:request_sync('textDocument/hover', {
      textDocument = { uri = vim.uri_from_bufnr(0) },
      position = { line = spec.hover[1] - 1, character = spec.hover[2] - 1 },
    }, 60000, 0)
    local text = response and response.result and response.result.contents.value or ''
    local errors = {}
    for _, want in ipairs(spec.shows) do
      if not text:find(want, 1, true) then
        table.insert(errors, ('hover lacks %q: %q'):format(want, text))
      end
    end
    return errors
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
