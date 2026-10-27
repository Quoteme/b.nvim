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
      },
    },
  },
  treesitter = true,
}

local function show_message(err, result, ctx)
  -- The server reports "Evaluation done: N problem(s)" after every check.
  if result and result.type == vim.lsp.protocol.MessageType.Log then
    return
  end
  return vim.lsp.handlers['window/showMessage'](err, result, ctx)
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
