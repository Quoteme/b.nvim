" Neovim registers these filetypes in plugin/prob.lua.
if has('nvim')
  finish
endif

au BufNewFile,BufRead *.rmch setf b
" B definition files share their extension with other languages.
au BufRead *.def if match(getline(1, 20), '^\s*DEFINITIONS') >= 0 | set filetype=b | endif
