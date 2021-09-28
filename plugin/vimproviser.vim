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
let s:current_pair = ''
let s:last_triggered_pair = ''

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

function! s:map(pair_name) abort
    for [plug, rhs] in [
    \   ['<plug>(vimproviser-left)',  s:qualified_rhs(s:pairs[a:pair_name][0])],
    \   ['<plug>(vimproviser-right)', s:qualified_rhs(s:pairs[a:pair_name][1])],
    \]
        let original_maparg = s:original_maparg(rhs)
        if original_maparg["noremap"]
            execute 'nnoremap ' . plug . ' ' . original_maparg["rhs"]
        else
            execute 'nmap '     . plug . ' ' . original_maparg["rhs"]
        endif
    endfor
    let s:current_pair = a:pair_name
endfunction

function! s:map_last_triggered() abort
    if s:last_triggered_pair != '' && s:last_triggered_pair != s:current_pair
        call s:map(s:last_triggered_pair)
    endif
endfunction

command -nargs=0 VimproviserLast call s:map_last_triggered()

function! s:all_pairs() abort
    return sort(keys(s:pairs))
endfunction

function! s:list_pairs(ArgLead, CmdLine, CursorPos) abort
    let options = s:all_pairs()
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
    return s:current_pair
endfunction

function! s:error(message) abort
    echohl ErrorMsg
    echomsg a:message
    echohl None
endfunction

function! s:eval(rhs, noremap) abort
    let rhs = a:rhs
    let noremap = a:noremap
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
        call s:error(substitute(v:exception, '.*\zeE\d\+', '', ''))
    endtry
endfunction

function! s:trigger_and_eval(pair_name, rhs, noremap) abort
    let s:last_triggered_pair = a:pair_name
    call s:eval(a:rhs, a:noremap)
endfunction

function! s:register_trigger(trigger_lhs, pair_name) abort
    " Make `lhs` a trigger for `pair_name`
    let original_maparg = s:original_maparg(a:trigger_lhs)
    execute 'nnoremap ' . a:trigger_lhs
    \   . " <cmd>call <sid>trigger_and_eval("
    \       . string(a:pair_name)
    \       . ", "
    \       . string(substitute(original_maparg["rhs"], '<', '<lt>', ''))
    \       . ", "
    \       . original_maparg["noremap"]
    \   . ")<cr>"
endfunction

function! s:register_triggers() abort
    if ! exists('g:vimproviser_triggers')
        return
    endif
    for [pair_name, lhs_list] in items(g:vimproviser_triggers)
        if ! has_key(s:pairs, pair_name)
            call s:error(
            \    'Cannot use pair "'
            \    . pair_name
            \    . '" as a trigger target, define it in g:vimproviser_pairs first'
            \ )
            continue
        endif
        for lhs in lhs_list
            call s:register_trigger(lhs, pair_name)
        endfor
    endfor
endfunction

command -nargs=1 -complete=customlist,s:list_pairs VimproviserMap call s:map("<args>")
command -nargs=0 VimproviserRegisterTriggers call s:register_triggers()

call s:map("Characters")
