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
  return flymaker#done(a:file)
endfunction

command! -nargs=+ -complete=shellcmd FlyMaker call flymaker#run(<q-args>)
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

        call flymaker#run(make_cmd, flymakehandler#flymake(&errorformat, title))

    endif
endfunction


let s:fly_dict         = {} " buffer to balloon dict association


function! Balloon()
    let msg = ''

    if has_key( s:fly_dict, v:beval_bufnr )
        let balloon_dict = s:fly_dict[v:beval_bufnr]
        let current_line_text = getbufline(v:beval_bufnr, v:beval_lnum)[0]
        if has_key( balloon_dict, current_line_text )
            let msg = balloon_dict[current_line_text]
        endif
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
        let matchstr = 'match Error ''\('
    endif
    let qflist = getqflist()
    call s:FlyClearNoRedraw()
    for item in qflist
        if item.lnum != 0
            if bufexists(item.bufnr)

                let key = getbufline( item.bufnr, item.lnum )[0]
                let escaped_key = escape( key, '^$.?*\[]' )
                if has( 'balloon_eval' )
                if has_key( s:fly_dict, item.bufnr )
                    let balloon_dict = s:fly_dict[item.bufnr]
                else
                    let balloon_dict = {}
                endif
                if has_key( balloon_dict, key )
                    if has( 'balloon_multiline' )
                        let balloon_dict[key] = balloon_dict[key] . "\n" . item.text
                    endif
                else
                    let balloon_dict[key] = item.text
                endif
                let s:fly_dict[item.bufnr] = balloon_dict
                endif

                if v:version >= 702
                    call matchadd( 'Error', '^'.escaped_key.'$' )
                else
                    if found_count > 0
                        let matchstr = matchstr . '\|'
                    endif
                    let matchstr = matchstr . '^' . escaped_key . '$'
                endif

                let found_count += 1
            endif
        endif
    endfor
    if found_count > 0
        if v:version < 702
            let matchstr = matchstr . '\)'''
            execute matchstr
        endif
        redraw
        set ballooneval
    else
        call s:FlyDone()
    endif

endfunction

function s:FlyClearNoRedraw()
    let qfwasopen = 0
    if &buftype == 'quickfix'
        let qfwasopen = 1
        cclose
    endif
    "TODO neather clearmatches nor match seem to work if the quickfix is open
    if v:version >= 702

        call clearmatches()

        let s:fly_dict = {}
    else
        match
    endif
endfunction

function s:FlyDone()
    if g:FlymakerOn == 1
        call s:FlyClearNoRedraw()
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


