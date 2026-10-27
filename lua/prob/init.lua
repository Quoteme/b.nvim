local M = {}

---@class prob.Config
M.config = {
  lsp = {
    cmd = { 'b-language-server', '--stdio' },
    -- Sent to the server as the `prob` configuration section.
    settings = {
      prob = {
        probHome = 'DEFAULT',
        wdChecks = true,
        strictChecks = true,
        performanceHints = true,
        debugMode = false,
        -- Milliseconds ProB may spend on each proof obligation.
        poTimeout = 1000,
        -- States the model checker explores at most.
        modelCheckStates = 100000,
      },
    },
  },
  treesitter = true,
  -- Replace ASCII combinations by Event-B symbols while typing, like Rodin.
  keyboard = true,
}

local function show_message(err, result, ctx)
  -- The server reports "Evaluation done: N problem(s)" after every check.
  if result and result.type == vim.lsp.protocol.MessageType.Log then
    return
  end
  return vim.lsp.handlers['window/showMessage'](err, result, ctx)
end

--- Lists the proof obligations of the current file in the quickfix list.
--- The server answers `prob.showPOs` with the obligations and their status.
local function show_pos(command, ctx)
  local client = assert(vim.lsp.get_client_by_id(ctx.client_id))
  client:request('workspace/executeCommand', command, function(err, result)
    if err then
      return vim.notify('prob: ' .. err.message, vim.log.levels.ERROR)
    end
    local items = {}
    for _, po in ipairs(result or {}) do
      table.insert(items, {
        filename = vim.uri_to_fname(po.uri),
        lnum = po.line + 1,
        col = po.character + 1,
        type = po.status == 'disproved' and 'W' or (po.status == 'undischarged' and 'I' or ''),
        text = ('%s: %s%s'):format(po.name, po.status, po.detail ~= '' and (' (' .. po.detail .. ')') or ''),
      })
    end
    vim.fn.setqflist({}, 'r', { title = 'Proof obligations', items = items })
    vim.cmd('botright copen')
  end, ctx.bufnr)
end

--- Filetype of a B file: Event-B in Camille notation (`machine m0`,
--- `context c0`) uses lowercase keywords, classical B (`MACHINE M`) uppercase.
---@param bufnr integer
---@return 'b'|'eventb'
function M.detect(bufnr)
  local text = table.concat(vim.api.nvim_buf_get_lines(bufnr, 0, 100, false), '\n')
  text = text:gsub('/%*.-%*/', ' '):gsub('//[^\n]*', ' ')
  local word = text:match('^%s*([%a_]+)')
  return (word == 'machine' or word == 'context') and 'eventb' or 'b'
end

--- Whether the configured language server can be started.
function M.has_server()
  return vim.fn.executable(M.config.lsp.cmd[1]) == 1
end

--- Fall back to running probcli and filling the quickfix list.
local function enable_quickfix_checker()
  local group = vim.api.nvim_create_augroup('prob', { clear = true })
  vim.api.nvim_create_autocmd({ 'BufReadPost', 'BufWritePost' }, {
    group = group,
    pattern = { '*.mch', '*.ref', '*.imp', '*.rmch' },
    callback = function(args)
      -- probcli cannot load Event-B in Camille notation.
      if vim.bo[args.buf].filetype ~= 'eventb' then
        vim.fn['probcli#Check']()
      end
    end,
  })
end

local function enable_lsp()
  vim.lsp.config('prob', {
    cmd = M.config.lsp.cmd,
    filetypes = { 'b', 'eventb' },
    root_markers = { '.git' },
    settings = M.config.lsp.settings,
    handlers = { ['window/showMessage'] = show_message },
  })
  vim.lsp.commands['prob.showPOs'] = show_pos
  vim.lsp.enable('prob')
end

local function enable_treesitter()
  vim.api.nvim_create_autocmd('FileType', {
    group = vim.api.nvim_create_augroup('prob_treesitter', { clear = true }),
    pattern = { 'b', 'eventb' },
    callback = function(args)
      -- Without the parser, the regex syntax stays in place.
      pcall(vim.treesitter.start, args.buf, args.match)
    end,
  })
end

local function enable_keyboard()
  vim.api.nvim_create_autocmd('FileType', {
    group = vim.api.nvim_create_augroup('prob_keyboard', { clear = true }),
    pattern = 'eventb',
    callback = function(args)
      require('prob.keyboard').attach(args.buf)
    end,
  })
end

--- Lets the user pick an Event-B symbol and inserts it at the cursor.
function M.pick_symbol()
  require('prob.keyboard').pick()
end

function M.enable()
  if M.has_server() then
    pcall(vim.api.nvim_del_augroup_by_name, 'prob')
    enable_lsp()
  else
    enable_quickfix_checker()
  end
  if M.config.treesitter then
    enable_treesitter()
  else
    pcall(vim.api.nvim_del_augroup_by_name, 'prob_treesitter')
  end
  if M.config.keyboard then
    enable_keyboard()
  else
    pcall(vim.api.nvim_del_augroup_by_name, 'prob_keyboard')
  end
  vim.api.nvim_create_user_command('ProbSymbol', M.pick_symbol, { desc = 'Insert an Event-B symbol' })
end

---@param opts? prob.Config
function M.setup(opts)
  opts = opts or {}
  M.config = vim.tbl_deep_extend('force', M.config, opts)
  -- Lists merge by index, so a shorter command would keep default arguments.
  if opts.lsp and opts.lsp.cmd then
    M.config.lsp.cmd = opts.lsp.cmd
  end
  M.enable()
end

return M
