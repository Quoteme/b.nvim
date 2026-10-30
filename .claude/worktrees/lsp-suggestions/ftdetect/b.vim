" Neovim registers these filetypes in plugin/prob.lua.
if has('nvim')
  finish
endif

au BufNewFile,BufRead *.rmch setf b
" B definition files share their extension with other languages.
au BufRead *.def if match(getline(1, 20), '^\s*DEFINITIONS') >= 0 | set filetype=b | endif
" Event-B in Camille notation (machine m0, context c0) uses lowercase keywords.
au BufRead *.mch if match(getline(1, 100), '^\s*\(machine\|context\)\>') >= 0 && match(getline(1, 100), '^\s*\(MACHINE\|MODEL\|SYSTEM\|REFINEMENT\|IMPLEMENTATION\)\>') < 0 | set filetype=eventb | endif
