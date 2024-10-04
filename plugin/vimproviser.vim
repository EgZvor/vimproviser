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
    \   "Quickfix": [":cprevious", ":cnext"],
    \   "QuickfixFile": [":cpfile", ":cnfile"],
    \   "Tags": [":tprevious", ":tnext"],
    \}
if exists("g:vimproviser_pairs")
    let s:pairs = extendnew(s:default_pairs, g:vimproviser_pairs)
else
    let s:pairs = s:default_pairs
endif
let s:original_mappings = {}
let s:current_pair = {'name': 'Characters', 'count': 0}
let s:last_triggered_pair = {'name': 'Characters', 'count': 0}
let s:triggers_registered = 0

if has('patch-8.2.1665')
    let s:fuzzy = 1
else
    let s:fuzzy = 0
endif

function! s:in(target, from) abort
    return a:from->index(a:target) >= 0
endfunction

function! s:error(message) abort
    echohl ErrorMsg
    echomsg a:message
    echohl None
endfunction

function! s:list_pairs(options, ArgLead) abort
    let options = copy(a:options)
    let narrowed = []
    if a:ArgLead != ""
        if s:fuzzy
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

function! s:list_all_pairs(ArgLead, CmdLine, CursorPos) abort
    return s:list_pairs(sort(keys(s:pairs)), a:ArgLead)
endfunction

function! s:list_trigger_pairs(ArgLead, CmdLine, CursorPos) abort
    return s:list_pairs(sort(keys(g:vimproviser_triggers)), a:ArgLead)
endfunction

function! s:qualified_rhs(rhs) abort
    if a:rhs =~? "^:"
        return a:rhs . ""
    endif
    return a:rhs
endfunction

function! s:original_maparg(lhs) abort
    if !has_key(s:original_mappings, a:lhs)
        let maparg_dict = maparg(a:lhs, 'n', 0, 1)
        if maparg_dict == {} || maparg_dict['rhs'] =~? 'vimproviser'
            let s:original_mappings[a:lhs] = {'rhs': a:lhs, 'noremap': 1, 'silent': 1}
        else
            let s:original_mappings[a:lhs] = maparg_dict
\               ->copy()
\               ->filter({k, _ -> k->s:in(['rhs', 'noremap', 'silent'])})
        endif

        " Make sure the original script number is used in `s:map` .
        let orig_sid = get(maparg_dict, 'sid', '')
        if orig_sid
            let rhs = substitute(maparg_dict['rhs'], '<sid>\c', $'<snr>{orig_sid}_', 'g')
            let s:original_mappings[a:lhs]['rhs'] = rhs
        endif
    endif
    return s:original_mappings[a:lhs]
endfunction

function! s:map(pair_name, count=0) abort
    for [plug, rhs] in [
    \   ['<plug>(vimproviser-left)',  s:qualified_rhs(s:pairs[a:pair_name][0])],
    \   ['<plug>(vimproviser-right)', s:qualified_rhs(s:pairs[a:pair_name][1])],
    \]
        let original_maparg = s:original_maparg(rhs)
        let map = 'n' .. (original_maparg['noremap'] ? 'nore'  : '') .. 'map'
        let silent = original_maparg['silent'] ? '<silent>': ''
        let orig_rhs = original_maparg['rhs']
        execute $'{map} {silent} {plug} {a:count == 0 ? '' : a:count}{orig_rhs}'
    endfor
    let s:current_pair = {'name': a:pair_name, 'count': a:count}
    if exists('#User#VimproviserSet')
        doautocmd <nomodeline> User VimproviserSet
    endif
endfunction

function! s:map_last_triggered() abort
    if !s:triggers_registered
        call s:error('VimproviserLast requires g:vimproviser_triggers to be defined')
        return
    endif
    if s:last_triggered_pair != s:current_pair
        call s:map(s:last_triggered_pair.name, s:last_triggered_pair.count)
    endif
endfunction

function! s:update_last_triggered(pair, count)
    let s:last_triggered_pair = {'name': a:pair, 'count': a:count}
endfunction

function! s:register_trigger(trigger_lhs, pair_name) abort
    " Make `lhs` a trigger for `pair_name`
    let original_maparg = s:original_maparg(a:trigger_lhs)
    let map = 'n' . (original_maparg["noremap"] ? 'nore'  : '') . 'map'
    let silent = original_maparg["silent"] ? '<silent>': ''
    execute map . ' ' . silent . ' <expr> ' . a:trigger_lhs . ' <sid>update_last_triggered("' . a:pair_name . '", v:count) ?? "' . original_maparg["rhs"] . '"'
endfunction

function! VimproviserRegisterMultiple(pair_name, ...) abort
    if a:0 == 0
        throw 'Vimproviser: specify at least 1 key combination to turn into a trigger'
    endif

    if !has_key(s:pairs, a:pair_name)
        throw 'Vimproviser: cannot use pair "'
        \    . a:pair_name
        \    . '" as a trigger target, define it in g:vimproviser_pairs first'
        \ )
    endif
    for lhs in a:000
        call s:register_trigger(lhs, a:pair_name)
    endfor
endfunction

function! VimproviserRegisterTriggers() abort
    if !exists('g:vimproviser_triggers')
        return
    endif
    if s:triggers_registered
        call s:error('Cannot call VimproviserRegisterTriggers here, it was already called')
        return
    endif

    for [pair_name, lhs_list] in items(g:vimproviser_triggers)
        if !has_key(s:pairs, pair_name)
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
    let s:triggers_registered = 1
endfunction

function! VimproviserStatus() abort
    return s:current_pair.name
endfunction

command -nargs=1 -complete=customlist,s:list_all_pairs VimproviserMap call s:map("<args>")
command -nargs=1 -complete=customlist,s:list_trigger_pairs VimproviserTrigger call s:update_last_triggered("<args>", 0)
command -nargs=0 VimproviserLast call s:map_last_triggered()

VimproviserMap Characters
