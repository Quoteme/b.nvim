local M = {}

function M.check()
  local prob = require('prob')
  local health = vim.health

  health.start('prob.vim')

  if vim.fn.has('nvim-0.11') == 1 then
    health.ok('Neovim ' .. tostring(vim.version()))
  else
    health.error('Neovim 0.11 or newer is required for the language server')
  end

  local cmd = prob.config.lsp.cmd[1]
  if prob.has_server() then
    health.ok(('Language server `%s` found: %s'):format(cmd, vim.fn.exepath(cmd)))
  else
    health.warn(
      ('Language server `%s` not found, using the probcli quickfix checker instead'):format(cmd),
      { 'Install b-language-server, e.g. `nix profile install github:Quoteme/prob.vim#b-language-server`' }
    )
  end

  if vim.fn.executable(vim.g.prob_parser or 'probcli') == 1 then
    health.ok('probcli found: ' .. vim.fn.exepath(vim.g.prob_parser or 'probcli'))
  elseif not prob.has_server() then
    health.error('Neither the language server nor probcli is available')
  end

  if pcall(vim.treesitter.language.add, 'b') then
    health.ok('Tree-sitter parser `b` found')
  else
    health.warn('Tree-sitter parser `b` not found, falling back to regex highlighting', {
      'Build it from the tree-sitter-b directory of this plugin, or use the `prob-nvim` Nix package',
    })
  end
end

return M
