if vim.g.loaded_prob then
  return
end
vim.g.loaded_prob = true

vim.filetype.add({
  extension = {
    mch = function(_, bufnr)
      return require('prob').detect(bufnr)
    end,
    ref = 'b',
    imp = 'b',
    rmch = 'b',
    def = function(path, bufnr)
      -- B definition files share their extension with other languages.
      for _, line in ipairs(vim.api.nvim_buf_get_lines(bufnr, 0, 20, false)) do
        if line:find('^%s*DEFINITIONS') then
          return 'b'
        end
      end
      return require('vim.filetype.detect').def(path, bufnr)
    end,
  },
})

require('prob').enable()
