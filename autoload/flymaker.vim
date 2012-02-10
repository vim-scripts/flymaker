if v:version < 700
    finish
endif


" Modified AsyncCommand handlers

function! flymaker#flymake(format, title)
    return flymaker#fm("cgetfile", "quickfix", a:format, a:title)
endfunction

function! flymaker#flymake_add(format, title)
    return flymaker#fm("caddfile", "quickfix", a:format, a:title)
endfunction


function! flymaker#fm(command, list, format, title)
  " Load the result in the quickfix/locationlist
  let env = {
        \ 'title': a:title,
        \ 'command': a:command,
        \ 'list': a:list,
        \ 'format': a:format,
        \ 'mode': a:list == 'quickfix' ? 'c' : 'l',
        \ }
  function env.get(temp_file_name) dict
    let errorformat=&errorformat
    let &errorformat=self.format
    try
" TODO: Don't open the quickfix list!
"      exe 'botright ' . self.mode . "open"
      let cmd = self.command . ' ' . a:temp_file_name
      exe cmd
" TODO: Tell us when something silently completes, if the quickfix list
"       is already open.
    if len(getqflist()) == 0
        " if the output is empty, indicate success
        caddexpr 'The requested operation completed without error.'
    endif
" TODO: in case the command changed something, check the modified time
    checktime
      if type(self.title) == type("") && self.title != ""
        let w:quickfix_title = printf(self.title, len(self.mode == 'c' ? getqflist() : getloclist()))
      endif
      silent! wincmd p
    finally
      let &errorformat = errorformat
    endtry
  endfunction
  return flymakerutil#tab_restore(env)
endfunction

