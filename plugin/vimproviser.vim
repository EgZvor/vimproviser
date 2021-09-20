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

if ! exists("g:vimproviser_trigger_delay")
    let g:vimproviser_trigger_delay = 0.4
endif

function! s:qualified_rhs(rhs)
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
        let rhs = s:qualified_rhs(s:vimproviser_pairs[a:kind][0])
        " TODO: rhs is already a trigger, we have to use saved trigger_dict
        " values here. We should save them when creating a trigger.
        let trigger_dict = maparg(rhs, 'n', 0, 1)
        echoerr trigger_dict
        if trigger_dict == {}
            let real_rhs = rhs
            let noremap = 1
        else
            let real_rhs = trigger_dict["rhs"]
            let noremap = trigger_dict["noremap"]
        endif
        if noremap
            execute 'nnoremap <plug>(vimproviser-left) ' . real_rhs
        else
            execute 'nmap <plug>(vimproviser-left) ' . real_rhs
        endif
        let rhs = s:qualified_rhs(s:vimproviser_pairs[a:kind][1])
        let trigger_dict = maparg(rhs, 'n', 0, 1)
        if trigger_dict == {}
            let real_rhs = rhs
            let noremap = 1
        else
            let real_rhs = trigger_dict["rhs"]
            let noremap = trigger_dict["noremap"]
        endif
        if noremap
            execute 'nnoremap <plug>(vimproviser-right) ' . real_rhs
        else
            execute 'nmap <plug>(vimproviser-right) ' . real_rhs
        endif

    endif
    " " a:kind does not match the regex
    " if "Macros\|Characters" !~? a:kind
    "     call setreg('h', s:qualified_rhs(s:vimproviser_pairs[a:kind][0]), "c")
    "     call setreg('l', s:qualified_rhs(s:vimproviser_pairs[a:kind][1]), "c")
    " endif
endfunction

function! VimproviserKinds()
    return sort(extendnew(keys(s:vimproviser_pairs), ["Characters", "Macros"]))
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

function VimproviserStatus()
    return '[ ' . substitute(getreg('h') . ' ' . getreg('l'), '', '<cr>', 'g') . ' ]'
endfunction

let s:vimproviser_last_triggered = {}
call map(VimproviserKinds(), 'extend(s:vimproviser_last_triggered, {v:val: 0.0})')

let s:vimproviser_last_triggered = {
    \   "ArgList": 0.0,
    \   "Characters": 0.0,
    \   "Buffers": 0.0,
    \   "Changes": 0.0,
    \   "LocationList": 0.0,
    \   "LocationListFile": 0.0,
    \   "QuickFix": 0.0,
    \   "QuickFixFile": 0.0,
    \   "Tags": 0.0,
    \}


function VimproviserTrigger(kind)
    let new = reltimefloat(reltime())
    let old = s:vimproviser_last_triggered[a:kind]
    let s:vimproviser_last_triggered[a:kind] = new
    if (new - old) < g:vimproviser_trigger_delay
        if confirm('Would you like to Vimprovise with: ' . a:kind . '?', "&Yes\n&No", 2) == 1
            call s:map(a:kind)
        endif
    endif
endfunction


function s:rhs_and_vimprovise(rhs, kind, noremap) abort
    call VimproviserTrigger(a:kind)

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


function VimproviserMapTrigger(trigger_lhs, kind)
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
    execute 'nnoremap ' . lhs . " <cmd>call <sid>rhs_and_vimprovise('" . substitute(rhs, '<', '<lt>', '') .  "', '" . a:kind . "', " . noremap . ")<cr>"
endfunction

command -nargs=1 -complete=customlist,s:ListKinds VimproviserMap call s:map("<args>")

VimproviserMap Characters
