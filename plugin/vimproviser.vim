if exists('g:loaded_vimproviser')
    finish
endif

let g:loaded_vimproviser = 1
let s:default_pairs = {
    \   "ArgList": [":previous", ":next"],
    \   "Buffers": [":bprevious", ":bnext"],
    \   "Changes": ["g;", "g,"],
    \   "Characters": ["<left>", "<right>"],
    \   "LocationList": [":lprevious", ":lnext"],
    \   "LocationListFile": [":lpfile", ":lnfile"],
    \   "Macros": ["@h", "@l"],
    \   "QuickFix": [":cprevious", ":cnext"],
    \   "QuickFixFile": [":cpfile", ":cnfile"],
    \   "Tags": [":tprevious", ":tnext"],
    \}
if exists("g:vimproviser_pairs")
    let s:pairs = extendnew(s:default_pairs, g:vimproviser_pairs)
else
    let s:pairs = s:default_pairs
endif
let s:original_mappings = {}
let s:current_kind = ''
let s:last_triggered_kind = ''

function! s:qualified_rhs(rhs) abort
    if a:rhs =~? "^:"
        return a:rhs . ""
    endif
    return a:rhs
endfunction

function! s:original_maparg(lhs) abort
    if ! has_key(s:original_mappings, a:lhs)
        let maparg_dict = maparg(a:lhs, 'n', 0, 1)
        if maparg_dict == {}
            let maparg_dict = {"rhs": a:lhs, "noremap": 1}
        endif
        let s:original_mappings[a:lhs] = filter(maparg_dict, {key, val -> key == 'rhs' || key == 'noremap'})
    endif
    return s:original_mappings[a:lhs]
endfunction

function! s:map(kind) abort
    for [plug, rhs] in [
    \   ['<plug>(vimproviser-left)',  s:qualified_rhs(s:pairs[a:kind][0])],
    \   ['<plug>(vimproviser-right)', s:qualified_rhs(s:pairs[a:kind][1])],
    \]
        let original_maparg = s:original_maparg(rhs)
        if original_maparg["noremap"]
            execute 'nnoremap ' . plug . ' ' . original_maparg["rhs"]
        else
            execute 'nmap '     . plug . ' ' . original_maparg["rhs"]
        endif
    endfor
    let s:current_kind = a:kind
endfunction

function! s:map_last_triggered() abort
    if s:last_triggered_kind != '' && s:last_triggered_kind != s:current_kind
        call s:map(s:last_triggered_kind)
    endif
endfunction

command -nargs=0 VimproviserLast call s:map_last_triggered()

function! VimproviserKinds() abort
    return sort(extendnew(keys(s:pairs), ["Characters", "Macros"]))
endfunction

function! s:ListKinds(ArgLead, CmdLine, CursorPos) abort
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

function! VimproviserStatus() abort
    return s:current_kind
endfunction

function! s:eval(maparg_dict) abort
    let rhs = a:maparg_dict["rhs"]
    let noremap = a:maparg_dict["noremap"]
    if noremap == 1
        let normal = 'normal! '
    else
        let normal = 'normal '
    endif

    if '<plug>' =~? rhs
        let command =  rhs
    else
        let command =  eval('"' . escape(rhs, '<') . '"')
    endif

    try
        execute normal . command
    catch /^Vim\%((\a\+)\)\=:E/
        echohl ErrorMsg
        echomsg substitute(v:exception, '.*\zeE\d\+', '', '')
        echohl None
    endtry
endfunction

function! s:trigger_and_eval(kind, maparg_dict) abort
    let s:last_triggered_kind = a:kind
    call s:eval(a:maparg_dict)
endfunction

function! VimproviserRegisterTrigger(trigger_lhs, kind) abort
    " Make `lhs` trigger `kind`
    let original_maparg = s:original_maparg(a:trigger_lhs)
    execute 'nnoremap ' . a:trigger_lhs
    \   . " <cmd>call <sid>trigger_and_eval('" . a:kind . "', " . substitute(string(original_maparg), '<', '<lt>', '') . ")<cr>"
endfunction

command -nargs=1 -complete=customlist,s:ListKinds VimproviserMap call s:map("<args>")

call s:map("Characters")
