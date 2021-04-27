# Vimproviser

Remap `h` and `l` keys for common actions with an ease!

## How to use

Run the command to choose situational mappings for `h` and `l`

For example:

``` vim
:VimproviserMap QuickFix
```

will remap `h` to `:cprevious<cr>` and `l` to `:cnext<cr>`.

Try other arguments
``` vim
" gT and gt
:VimproviserMap Tab
" @h and @l -- improvise away!
:VimproviserMap Macros
" h and l -- boooring
:VimproviserMap Literal
```

Use completion `<c-d>` to see all available options.

## Configuration

To add your mappings to the default ones,
define the `g:vimproviser_pairs` variable in your `.vimrc`

``` vim
let g:vimproviser_pairs = {"Paragraph": ["{", "}"]}
```

You can then map them with

``` vim
:VimproviserMap Paragraph
```

There is no need to restrict yourself to movements if you feel adventurous

``` vim
let g:vimproviser_pairs = {"Yanks": ["yy", "pp"]}
```

## Example mappings

``` vim
nnoremap <space>B :VimproviserMap<space>
```

``` vim
" Using garybernhardt/selecta
function! ChooseKinds()
    let kinds = VimproviserKinds()
    try
        let kind = system('printf "' . join(kinds, "\n") . '" | selecta | tr -d "\n"')
    catch /Vim:Interrupt/
        redraw!
        return ""
    endtry
    redraw!
    return kind
endfunction

nnoremap <leader>B <cmd>exec 'VimproviserMap ' . ChooseKinds()<cr>
```
