if v:version < 700
    finish
endif


"TODO - Modified AsyncCommand implementation -- after the bugs are fixed, in
"       AsyncCommand, this can all go away.

if !has('clientserver')
  finish
endif


let s:receivers = {}
if has("win32")
    " Works in Windows (Win7 x64)
    function! s:Async_Impl(tool_cmd, vim_cmd)
        silent exec "!start /min cmd /c \"".a:tool_cmd." & ".a:vim_cmd."\""
    endfunction
    function! s:Async_Single_Impl(tool_cmd)
        silent exec "!start /min cmd /c \"".a:tool_cmd."\""
    endfunction
else
    " Works in linux (Ubuntu 10.04)
    function! s:Async_Impl(tool_cmd, vim_cmd)
        silent exec "! ( ".a:tool_cmd." ; ".a:vim_cmd." ) &"
    endfunction
    function! s:Async_Single_Impl(tool_cmd)
        silent exec "! ".a:tool_cmd." &"
    endfunction
endif


function! flymaker#run(command, ...)
  if len(v:servername) == 0
    echo "Error: Flymaker requires vim to be started with a servername."
    echo "       See :help --servername"
    return
  endif
  if a:0 == 1
    let Fn = a:1
    let env = 0
  elseif a:0 == 2
    let Fn = a:1
    let env = a:2
  else
    " execute in background
    return s:Async_Single_Impl(a:command)
  endif

  " String together and execute.
  let temp_file = tempname()

  let shellredir = &shellredir
  if match( shellredir, '%s') == -1
      " ensure shellredir has a %s so printf works
      let shellredir .= '%s'
  endif

  " Grab output and error in case there's something we should see

" FIXED: fixed redirection bug if last arg of shell command is 1 or 2
  let tool_cmd = a:command . ' ' . printf(shellredir, temp_file)
"       by adding this space  ^

  if type(Fn) == type({})
              \ && has_key(Fn, 'get')
              \ && type(Fn.get) == type(function('flymaker#run'))
    " Fn is a dictionary and Fn.get is the function we should execute on
    " completion.
    let s:receivers[temp_file] = {'func': Fn.get, 'dict': Fn}
  else
    let s:receivers[temp_file] = {'func': Fn, 'dict': env}
  endif

  if exists('g:asynccommand_prg')
    let prg = g:asynccommand_prg
  elseif has("gui_macvim") && executable('mvim')
    let prg = "mvim"
  else
    let prg = "vim"
  endif

  let vim_cmd = prg . " --servername " . v:servername . " --remote-expr \"FlyMakerDone('" . temp_file . "')\" "

  call s:Async_Impl(tool_cmd, vim_cmd)
endfunction

function! flymaker#done(temp_file_name)
  " Called on completion of the task
  let r = s:receivers[a:temp_file_name]
  if type(r.dict) == type({})
    call call(r.func, [a:temp_file_name], r.dict)
  else
    call call(r.func, [a:temp_file_name])
  endif
  unlet s:receivers[a:temp_file_name]
  delete a:temp_file_name
" FIXED: by default 0 is returned (and it was being echoed to the screen!)
"        Need to investigate if this is the right thing to do or not.
  return ''
endfunction

