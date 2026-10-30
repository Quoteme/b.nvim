" Neovim is set up in plugin/prob.lua.
if has('nvim')
  finish
endif

augroup prob
  au!
  autocmd! BufWritepost,FileWritePost,BufReadPost *.mch,*.ref,*.imp,*.rmch call probcli#Check()
augroup END
