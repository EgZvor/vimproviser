if exists('g:loaded_vimproviser')
    finish
endif

let g:loaded_vimproviser = 1

let s:default_vimproviser_pairs = {
    \   "Literal": ["h", "l"],
    \   "QuickFix": [":cprevious<cr>", ":cnext<cr>"],
    \   "QuickFixFile": [":cpfile<cr>", ":cnfile<cr>"],
    \   "LocationList": [":lprevious<cr>", ":lnext<cr>"],
    \   "LocationListFile": [":lpfile<cr>", ":lnfile<cr>"],
    \   "Tab": ["gT", "gt"],
    \   "Macros": ["@h", "@l"],
    \}

if exists("g:vimproviser_pairs")
    let g:vimproviser_pairs = extendnew(s:default_vimproviser_pairs, g:vimproviser_pairs)
else
    let g:vimproviser_pairs = s:default_vimproviser_pairs
endif

function! s:VimproviserMap(kind)
    exec 'nnoremap h ' . g:vimproviser_pairs[a:kind][0]
    exec 'nnoremap l ' . g:vimproviser_pairs[a:kind][1]
endfunction

function! s:ListKinds(ArgLead, CmdLine, CursorPos)
    let options = keys(g:vimproviser_pairs)
    let narrowed = []
    for option in options
        if option =~ a:ArgLead
            call add(narrowed, option)
        endif
    endfor
    return narrowed
endfunction

command -nargs=1 -complete=customlist,s:ListKinds VimproviserMap call s:VimproviserMap("<args>")
