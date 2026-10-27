-- Opens every file in TestFiles/ with the prob language server attached and
-- prints the diagnostics it reports, in the format of prob-vim-test.
--
-- Usage: nvim --headless -u NONE --cmd 'set rtp^=.' --cmd 'filetype plugin on' \
--          -c 'runtime plugin/prob.lua' -c 'luafile tests/lsp_diagnostics.lua'

local done = false
vim.lsp.config('prob', {
  handlers = {
    ['window/showMessage'] = function(_, result)
      if result.message:find('^Evaluation done') then
        done = true
      end
    end,
  },
})

local files = vim.fn.glob('TestFiles/*.mch', false, true)
vim.list_extend(files, vim.fn.glob('TestFiles/*.rmch', false, true))

local failed = false
for _, file in ipairs(files) do
  done = false
  vim.cmd.edit(file)
  print('-- ' .. file)
  if not vim.wait(60000, function() return done end, 100) then
    print('(timed out waiting for the language server)')
    failed = true
  end

  local lines = {}
  for _, d in ipairs(vim.diagnostic.get()) do
    local name = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(d.bufnr), ':.')
    table.insert(lines, ('%s:%d:%d: %s'):format(name, d.lnum + 1, d.col + 1, d.message:gsub('\n', ' ')))
  end
  table.sort(lines)
  print(#lines > 0 and table.concat(lines, '\n') or '(no errors)')

  vim.diagnostic.reset()
  vim.cmd('silent! %bwipeout!')
end

vim.cmd(failed and 'cquit' or 'qall!')
