if v:version < 700
    finish
endif


" default configuration (override in your .vimrc)
if !exists('g:FlymakerOn')
    " default flymaker to off
    let g:FlymakerOn = 0
endif
if !exists('g:FlymakerMenu')
    " default the menu to off
    let g:FlymakerMenu = 0
endif


if g:FlymakerMenu == 1 && has('menu')
    " Flymaker
    let s:flymaker = 'Flymaker'
        " On
        let s:flymaker_on = s:flymaker.'.On'
        execute 'amenu <silent> '.s:flymaker_on.' :FlyOn<CR>'
        " Off
        let s:flymaker_off = s:flymaker.'.Off'
        execute 'amenu <silent> '.s:flymaker_off.' :FlyOff<CR>'
endif


function! FlyMakerDone(file)
  return flymakerutil#done(a:file)
endfunction

command! -nargs=+ -complete=shellcmd FlyMaker call flymakerutil#run(<q-args>)
command! -nargs=* AsyncFlyMake call s:AsyncFlyMake(<q-args>)
command! -nargs=0 FlyDone call s:FlyDone()
command! -nargs=0 FlyOn call s:FlyOn()
command! -nargs=0 FlyOff call s:FlyOff()
command! -nargs=0 FlyToggle call s:FlyToggle()


" FlyMake
"   - uses the current make program
"   - optional parameter for make target(s)
function! s:AsyncFlyMake(target)
    if g:FlymakerOn == 1

        let make_cmd = &makeprg ." ". a:target
        let title = 'Make: '
        if a:target == ''
            let title .= "(default)"
        else
            let title .= a:target
        endif
        call flymakerutil#run(make_cmd, flymaker#flymake(&errorformat, title))

    endif
endfunction


let s:balloon_dict = {}


function! Balloon()
    let msg = ''

    if has_key( s:balloon_dict, getline(v:beval_lnum) )
        let msg = s:balloon_dict[getline(v:beval_lnum)]
    endif

    return msg
endfunction
if has("gui_running") && has("balloon_eval")
    set balloonexpr=Balloon()
endif


function! Fly()
    let found_count = 0
    if v:version < 702
        " since matchadd is not available, we must construct a big
        " long regular expression and make a single call to match.
        let matchstr = 'match Error /^\('
    endif
    for item in getqflist()
        if item.lnum != 0
            "TODO - create a dict with bufnr and match expr so that
            "       we can goto each buffer and highlight matches,
            "       rather than worry about which buffer we're in?
            if bufnr("%") == item.bufnr

                let s:balloon_dict[getline(item.lnum)] = item.text

                if v:version >= 702
                    call matchadd('Error',getline(item.lnum))
                else
                    if found_count > 0
                        let matchstr = matchstr . '\|'
                    endif
                    let matchstr = matchstr . getline(item.lnum)
                endif

                let found_count += 1
            endif
        endif
    endfor
    if found_count > 0
        if v:version < 702
            let matchstr = matchstr . '\)$/'
            execute matchstr
        endif
        redraw
        set ballooneval
    else
        call s:FlyDone()
    endif
endfunction


function s:FlyDone()
    if g:FlymakerOn == 1
        if v:version >= 702
            call clearmatches()
        else
            match
        endif
        redraw
        set noballooneval
    endif
endfunction


function s:FlyOn()
        let g:FlymakerOn = 1
endfunction


function s:FlyOff()
        call s:FlyDone()
        let g:FlymakerOn = 0
endfunction


function s:FlyToggle()
    if g:FlymakerOn == 1
        call s:FlyOff()
    else
        call s:FlyOn()
    endif
endfunction


