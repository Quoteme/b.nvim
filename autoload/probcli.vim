" TODO: Avoid putting focus on quickfixlist or locationlist
" TODO: CHECK opening files in different dirs, java parser only prints
" filename and not the path information
"
if exists("g:loaded_probcli")
    finish
endif

let g:loaded_probcli = 1
" probcli >= 1.16
set errorformat+=%E\!\ An\ error\ occurred\ (source:\ %m)\ \!,%Z\!\ Line:\ %l\ Column:\ %c\ until\ %.%#\ in\ file:\ %f,%C\!\ %m
set errorformat+=%E\!\ An\ error\ occurred\ \!,%Z\!\ Line:\ %l\ Column:\ %c\ %s\ in\ file:\ %f,%C\!\ source(%m),%C\!\ %m,%-G%.%#
" old error formats
set errorformat+=%E\!\ source(parse_error),%C\!\ [%*\\d\\,%*\\d]\ %m\ in\ file%.%#
set errorformat+=%W\!\ source(type_error),%Z\!\ Line:\ %l\ Column:\ %c\ in\ file\ %f,%C\!\ %m\ in\ file%.%#,%-G\!\ \/%.%#,%C\!\ %m,%-G%.%#

if !exists("g:prob_parser")
  let g:prob_parser="probcli"
end

function! probcli#Check() "{{{1
  let cmd=g:prob_parser ." -p MAX_INITIALISATIONS 0 -p show_full_error_span true ". @%
  if has('nvim')
    call s:ProbAsyncNvim(cmd)
  elseif exists('*job_start')
    call s:ProbAsync(cmd)
  else
    call s:ProbSync(cmd)
  endif
endfunction

function! s:ProbAsyncNvim(cmd)
  if exists('g:backgroundProBOutput')
    return
  endif
  cclose
  "
  let g:backgroundProBOutput = []
  let l:options = {'on_stderr': function('s:NvimErrorCallback'), 'stderr_buffered': v:true, 'on_exit': function('s:NvimExitCallback')}

  if jobstart(a:cmd, l:options) <= 0
    unlet g:backgroundProBOutput
    call s:ProbSync(a:cmd)
  endif
endfunction

function! s:NvimErrorCallback(job_id, data, event)
  let g:backgroundProBOutput += filter(copy(a:data), 'v:val !=# ""')
endfunction

function! s:NvimExitCallback(job_id, code, event)
  call probcli#closeCallback(a:job_id)
endfunction

function! s:ProbAsync(cmd)
  if exists('g:backgroundProBOutput')
    return
  endif
  "
  " echo "Calling ProB to check file..."
  cclose
  "
  let g:backgroundProBOutput = []
  let l:options = {'close_cb': 'probcli#closeCallback', 'out_io': 'null', 'err_cb': 'probcli#errorCallback', 'err_io': 'buffer'}

	let job = job_start(a:cmd, l:options)
endfunction

function! probcli#errorCallback(channel, msg)
  let g:backgroundProBOutput += [a:msg]
endfunction

function! probcli#closeCallback(channel)
  cgete g:backgroundProBOutput
  cw
  unlet g:backgroundProBOutput
endfunction

function! s:ProbSync(cmd)
  cclose
  "
  let l:prob_lines=split(system(a:cmd .' 1>/dev/null'), '\n')
  cgete l:prob_lines
  cw
endfunction " }}}1
