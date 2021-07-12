if exists('g:loaded_vimproviser')
    finish
endif

let g:loaded_vimproviser = 1

let s:default_vimproviser_pairs = {
    \   "ArgList": [":previous", ":next"],
    \   "Buffers": [":bprevious", ":bnext"],
    \   "Changes": ["g;", "g,"],
    \   "LocationList": [":lprevious", ":lnext"],
    \   "LocationListFile": [":lpfile", ":lnfile"],
    \   "QuickFix": [":cprevious", ":cnext"],
    \   "QuickFixFile": [":cpfile", ":cnfile"],
    \   "Tags": [":tprevious", ":tnext"],
    \}

if exists("g:vimproviser_pairs")
    let s:vimproviser_pairs = extendnew(s:default_vimproviser_pairs, g:vimproviser_pairs)
else
    let s:vimproviser_pairs = s:default_vimproviser_pairs
endif

function! s:qualified_rhs(rhs)
    if a:rhs =~? "^:"
        return a:rhs . ""
    return a:rhs
endfunction

function! s:map(kind)
    if a:kind == "Literal"
        nnoremap <plug>(vimproviser-left) h
        nnoremap <plug>(vimproviser-right) l
    else
        nnoremap <plug>(vimproviser-left) @h
        nnoremap <plug>(vimproviser-right) @l
    endif

    " a:kind does not match the regex
    if "Macros\|Literal" !~? a:kind
        call setreg('h', s:qualified_rhs(s:vimproviser_pairs[a:kind][0]), "c")
        call setreg('l', s:qualified_rhs(s:vimproviser_pairs[a:kind][1]), "c")
    endif
endfunction

function! VimproviserKinds()
    return sort(extendnew(keys(s:vimproviser_pairs), ["Literal", "Macros"]))
endfunction

function! s:ListKinds(ArgLead, CmdLine, CursorPos)
    let options = VimproviserKinds()
    let narrowed = []
    if a:ArgLead != ""
        if exists('*matchfuzzy')
            let narrowed = matchfuzzy(options, a:ArgLead)
        else
            for option in options
                if option =~ a:ArgLead
                    call add(narrowed, option)
                endif
            endfor
        endif
        return narrowed
    else
        return options
    endif
endfunction

command -nargs=1 -complete=customlist,s:ListKinds VimproviserMap call s:map("<args>")

nnoremap <plug>(vimproviser-left) h
nnoremap <plug>(vimproviser-right) l
nnoremap <plug>(vimproviser-show) <cmd>echo substitute('[ ' . getreg('h') . ' \| ' . getreg('l') . ' ]', '\r\n', '^M', "g")<cr>
