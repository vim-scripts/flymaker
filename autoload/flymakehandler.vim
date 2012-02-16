if v:version < 700
    finish
endif


" Modified AsyncCommand handlers

function! flymakehandler#flymake(format, title)
    return flymakehandler#fm("cgetfile", "quickfix", a:format, a:title)
endfunction


function! flymakehandler#fm(command, list, format, title)
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
      let cmd = self.command . ' ' . a:temp_file_name
      exe cmd
      if type(self.title) == type("") && self.title != ""
        let w:quickfix_title = printf(self.title, len(self.mode == 'c' ? getqflist() : getloclist()))
      endif
      silent! wincmd p
    finally
      let &errorformat = errorformat
    endtry
    " post-process the now-populated quickfix list
    call Fly()
  endfunction
  return asynccommand#tab_restore(env)
endfunction

