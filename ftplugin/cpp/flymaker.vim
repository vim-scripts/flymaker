
" Please take the time to read through the Configuration
" section of the documentation to fine tune this gui!
"
" :help flymaker


"setlocal makeprg=make
if has("autocmd")
" Uses quickfix list notifications (Requires AsyncCommand 3.1)
"    autocmd BufWritePost <buffer> :AsyncMake
" Uses flymake-like notifications
    autocmd BufWritePost <buffer> :AsyncFlyMake
endif

