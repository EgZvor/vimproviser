if exists('g:loaded_lazybrowser')
    finish
endif

let g:loaded_lazybrowser = 1

let s:default_lazy_browser_pairs = {
    \   "Literal": ["h", "l"],
    \   "QuickFix": [":cprevious<cr>", ":cnext<cr>"],
    \   "QuickFixFile": [":cpfile<cr>", ":cnfile<cr>"],
    \   "LocationList": [":lprevious<cr>", ":lnext<cr>"],
    \   "LocationListFile": [":lpfile<cr>", ":lnfile<cr>"],
    \   "Tab": ["gT", "gt"],
    \   "Macros": ["@h", "@l"],
    \}

if exists("g:lazy_browser_pairs")
    let g:lazy_browser_pairs = extendnew(s:default_lazy_browser_pairs, g:lazy_browser_pairs)
else
    let g:lazy_browser_pairs = s:default_lazy_browser_pairs
endif

function! s:LazyBrowserMap(kind)
    exec 'nnoremap h ' . g:lazy_browser_pairs[a:kind][0]
    exec 'nnoremap l ' . g:lazy_browser_pairs[a:kind][1]
endfunction

function! s:ListKinds(ArgLead, CmdLine, CursorPos)
    let options = keys(g:lazy_browser_pairs)
    let narrowed = []
    for option in options
        if option =~ a:ArgLead
            call add(narrowed, option)
        endif
    endfor
    return narrowed
endfunction

command -nargs=1 -complete=customlist,s:ListKinds LazyBrowserMap call s:LazyBrowserMap("<args>")

nnoremap <Plug>(LazyBrowserMap) :LazyBrowserMap<space>
nnoremap <Plug>(LazyBrowserClear) <cmd>call setreg('h', '') <bar> call setreg('l', '')<cr>
