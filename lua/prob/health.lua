local M = {}

function M.check()
  local prob = require('prob')
  local health = vim.health

  health.start('b.nvim')

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
      { 'Put b-language-server on PATH, e.g. github:Quoteme/b.nvim#b-language-server (see the README)' }
    )
  end

  -- A running server older than the plugin lacks hover, the animator or the prover.
  for _, client in ipairs(vim.lsp.get_clients({ name = 'prob' })) do
    local caps = client.server_capabilities or {}
    local commands = vim.tbl_get(caps, 'executeCommandProvider', 'commands') or {}
    local missing = {}
    if not caps.hoverProvider then
      table.insert(missing, 'hover')
    end
    if not vim.tbl_contains(commands, 'prob.animate') then
      table.insert(missing, 'animation')
    end
    if not vim.tbl_contains(commands, 'prob.visualize') then
      table.insert(missing, 'visualisations')
    end
    if not vim.tbl_contains(commands, 'prob.prove') then
      table.insert(missing, 'interactive proofs')
    end
    if #missing == 0 then
      health.ok(
        ('Running language server (client %d) supports hover, animation, visualisations and interactive proofs'):format(client.id)
      )
    else
      health.error(
        ('Running language server (client %d) is older than the plugin: no %s'):format(client.id, table.concat(missing, ', ')),
        {
          ('It was started as `%s` from %s'):format(cmd, vim.fn.exepath(cmd)),
          'Update the b.nvim flake input that provides it (e.g. `nix flake update`) and restart Neovim',
        }
      )
    end
  end

  if vim.fn.executable(vim.g.prob_parser or 'probcli') == 1 then
    health.ok('probcli found: ' .. vim.fn.exepath(vim.g.prob_parser or 'probcli'))
  elseif not prob.has_server() then
    health.error('Neither the language server nor probcli is available')
  end

  -- ProB Tcl/Tk and probcli call `dot` for their graphs; the Nix language server brings its own.
  if vim.fn.executable('dot') == 1 then
    health.ok('Graphviz found: ' .. vim.fn.exepath('dot'))
  else
    health.info('Graphviz `dot` not on Neovim\'s PATH: the language server needs it for graphs (the Nix package includes it)')
  end

  for _, lang in ipairs({ 'b', 'eventb' }) do
    if pcall(vim.treesitter.language.add, lang) then
      health.ok(('Tree-sitter parser `%s` found'):format(lang))
    else
      health.warn(('Tree-sitter parser `%s` not found, no tree-sitter highlighting for it'):format(lang), {
        ('Build it from the tree-sitter-%s directory of this plugin, or use the `b-nvim` Nix package'):format(lang),
      })
    end
  end
end

return M
