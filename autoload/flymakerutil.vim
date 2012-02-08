" Modified AsyncCommand implementation

if !has('clientserver')
  finish
endif


" TODO: I had to include this for the other functions included here
"       because of the script-scope of the functions in AsyncCommand.  :(
"       (They are unmodified.)
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


function! flymakerutil#run(command, ...)
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

" TODO: fixed redirection bug if last arg of shell command is 1 or 2
  let tool_cmd = a:command . ' ' . printf(shellredir, temp_file)
"       by adding this space  ^

  if type(Fn) == type({})
              \ && has_key(Fn, 'get')
              \ && type(Fn.get) == type(function('flymakerutil#run'))
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

function! flymakerutil#done(temp_file_name)
  " Called on completion of the task
  let r = s:receivers[a:temp_file_name]
  if type(r.dict) == type({})
    call call(r.func, [a:temp_file_name], r.dict)
  else
    call call(r.func, [a:temp_file_name])
  endif
  unlet s:receivers[a:temp_file_name]
  delete a:temp_file_name
" TODO: by default 0 is returned (and it was being echoed to the screen!)
"       Need to investigate if this is the right thing to do or not.  This
"       may be related to the GTK errors in the terminal when in GUI mode.
  return ''
endfunction

function! flymakerutil#tab_restore(env)
  let env = {
        \ 'tab': tabpagenr(),
        \ 'env': a:env,
        \ }
  function env.get(temp_file_name) dict
    let lazyredraw = &lazyredraw
    let &lazyredraw = 1
    let current_tab = tabpagenr()
    try
      silent! exec "tabnext " . self.tab
      " self.env.get is not this function -- it's the function passed to
      " tab_restore()
      call call(self.env.get, [a:temp_file_name], self.env)
      silent! exe "tabnext " . current_tab
      redraw
    finally
      let &lazyredraw = lazyredraw
    endtry

" TODO: At this point, the quickfix list is populated.
    call Fly()

  endfunction
  return env
endfunction

