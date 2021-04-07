# Lazy Browser

Remap `h` and `l` keys for common actions with an ease!

## How to use

Run the command to choose situational mappings for `h` and `l`

For example:

``` vim
:LazyBrowserMap QuickFix
```

will remap `h` to `:cprevious<cr>` and `l` to `:cnext<cr>`.

Try other arguments
``` vim
" gT and gt
:LazyBrowserMap Tab
" @h and @l -- improvise away!
:LazyBrowserMap Macros
" h and l -- boooring
:LazyBrowserMap Literal
```

Use completion `<c-d>` to see all available options.

## Configuration

To add your mappings to the default ones,
define the `g:lazy_browser_pairs` variable in your `.vimrc`

``` vim
let g:lazy_browser_pairs = {"Paragraph": ["{", "}"]}
```

You can then map them with

``` vim
:LazyBrowserMap Paragraph
```

There is no need to restrict yourself to movements if you feel adventurous

``` vim
let g:lazy_browser_pairs = {"Yanks": ["yy", "pp"]}
```

## Example mapping

``` vim
nnoremap <space>B :LazyBrowserMap<space>
```
