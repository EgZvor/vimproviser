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
    let s:pairs = extendnew(s:default_vimproviser_pairs, g:vimproviser_pairs)
else
    let s:pairs = s:default_vimproviser_pairs
endif

if ! exists("g:vimproviser_trigger_frequency")
    let g:vimproviser_trigger_frequency = 3
endif

let s:vimproviser_trigger_window = 60

function! s:qualified_rhs(rhs) abort
    if a:rhs =~? "^:"
        return a:rhs . ""
    endif
    return a:rhs
endfunction

function! s:map(kind) abort
    if a:kind == "Characters"
        nnoremap <plug>(vimproviser-left) <left>
        nnoremap <plug>(vimproviser-right) <right>
    elseif a:kind == "Macros"
        nnoremap <plug>(vimproviser-left) @h
        nnoremap <plug>(vimproviser-right) @l
    else
        " TODO: Refactor the shit out of this.
        for [plug, pair_n] in [['<plug>(vimproviser-left)', 0], ['<plug>(vimproviser-right)', 1]]
            let rhs = s:qualified_rhs(s:pairs[a:kind][pair_n])
            let trigger_dict = get(s:original_mappings, rhs, maparg(rhs, 'n', 0, 1))
            if trigger_dict == {}
                let real_rhs = rhs
                let noremap = 1
            else
                let real_rhs = trigger_dict["rhs"]
                let noremap = trigger_dict["noremap"]
            endif
            if noremap
                execute 'nnoremap ' . plug . ' ' . real_rhs
            else
                execute 'nmap ' . plug . ' ' . real_rhs
            endif
        endfor
    endif
    let g:vimproviser_current_kind = a:kind
endfunction

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

function VimproviserStatus() abort
    " return '[ ' . substitute(getreg('h') . ' ' . getreg('l'), '', '<cr>', 'g') . ' ]'
    return g:vimproviser_current_kind
endfunction

let s:original_mappings = {}
let s:last_triggered = {}


function s:trigger_and_suggest_mapping(kind) abort
    " Check if provided kind was triggered more than
    " g:vimproviser_trigger_frequency times in the last minute
    let now = reltimefloat(reltime())
    if ! has_key(s:last_triggered, a:kind)
        let s:last_triggered[a:kind] = []
    endif
    let kind_trigger_times = s:last_triggered[a:kind]
    " Filter out old trigger info
    call filter(kind_trigger_times, {idx, val -> val >= (now - s:vimproviser_trigger_window)})
    if len(kind_trigger_times) < g:vimproviser_trigger_frequency
        call add(kind_trigger_times, now)
    endif
    if len(kind_trigger_times) >= g:vimproviser_trigger_frequency
    \  && confirm('Would you like to Vimprovise with: ' . a:kind . '?', "&Yes\n&No", 2) == 1
        call s:map(a:kind)
    endif
endfunction


function s:rhs_and_vimprovise(rhs, kind, noremap) abort
    " Trigger specified kind and evaluate rhs correctly
    call s:trigger_and_suggest_mapping(a:kind)

    if a:noremap == 1
        let normal = 'normal! '
    else
        let normal = 'normal '
    endif

    if '<plug>' =~? a:rhs
        let cmd = normal . a:rhs
    else
        let cmd = normal . eval('"' . escape(a:rhs, '<') . '"')
    endif

    try
        execute cmd
    catch /^Vim\%((\a\+)\)\=:E/
        echohl ErrorMsg
        echomsg substitute(v:exception, '.*\zeE\d\+', '', '')
        echohl None
    endtry
endfunction


function VimproviserMapTrigger(trigger_lhs, kind) abort
    " Map provided lhs to whatever it was mapped to + triggering specified kind
    let trigger_dict = maparg(a:trigger_lhs, 'n', 0, 1)
    if trigger_dict == {}
        let lhs = a:trigger_lhs
        let rhs = a:trigger_lhs
        let noremap = 1
    else
        let lhs = trigger_dict["lhs"]
        let rhs = trigger_dict["rhs"]
        let noremap = trigger_dict["noremap"]
    endif
    " Save original rhs to map <plug>(vimproviser-*) to it
    let s:original_mappings[a:trigger_lhs] = {"rhs": rhs, "noremap": noremap}
    execute 'nnoremap ' . lhs . " <cmd>call <sid>rhs_and_vimprovise('" . substitute(rhs, '<', '<lt>', '') .  "', '" . a:kind . "', " . noremap . ")<cr>"
endfunction

command -nargs=1 -complete=customlist,s:ListKinds VimproviserMap call s:map("<args>")

VimproviserMap Characters
