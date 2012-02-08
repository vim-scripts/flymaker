
function! FlyMakerDone(file)
  return flymakerutil#done(a:file)
endfunction

command! -nargs=+ -complete=shellcmd FlyMaker call flymakerutil#run(<q-args>)
command! -nargs=* AsyncFlyMake call s:AsyncFlyMake(<q-args>)


" FlyMake
"   - uses the current make program
"   - optional parameter for make target(s)
function! s:AsyncFlyMake(target)
    let make_cmd = &makeprg ." ". a:target
    let title = 'Make: '
    if a:target == ''
        let title .= "(default)"
    else
        let title .= a:target
    endif
    call flymakerutil#run(make_cmd, flymaker#flymake(&errorformat, title))
endfunction


function! Balloon()

    let msg = ''
    for item in getqflist()
        if v:beval_lnum == item.lnum
            let msg = item.text . "\n\n\":copen\" for more information"
            break
        endif
    endfor
    return msg
endfunction
if has("balloon_eval")
    set balloonexpr=Balloon()
endif


function! Fly()
    let matchstr = 'match Error /\%'
    let needsep = 0
    for item in getqflist()
        if item.lnum != 0
            "TODO - create a dict with bufnr and match expr so that
            "       we can goto each buffer and highlight matches,
            "       rather than worry about which buffer we're in.
            if bufnr("%") == item.bufnr
                if needsep == 1
                    let matchstr = matchstr . '\|\%'
                endif
                let matchstr = matchstr . item.lnum . 'l'
                let needsep = 1
            endif
        endif
    endfor
    if needsep == 1
        let matchstr = matchstr . '/'

        execute matchstr
        redraw

        set ballooneval
    else

        match
        redraw

        set noballooneval
    endif
endfunction


