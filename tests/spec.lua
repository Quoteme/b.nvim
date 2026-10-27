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
