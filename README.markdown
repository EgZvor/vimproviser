# Vimproviser

Vimproviser was designed to repeat motions.

Vimproviser provides commands and mappings that allow for a quick remapping of
two of your most convenient keys to actions that are most important for you
right now.

## How to use

Map some convenient keys to Vimproviser mappings

``` vim
nmap h <plug>(vimproviser-left)
nmap l <plug>(vimproviser-right)
```

Run the command to choose situational mappings for `h` and `l`

For example:

``` vim
:VimproviserMap QuickFix
```

will remap `h` to `:cprevious<cr>` and `l` to `:cnext<cr>`.

Try other arguments
``` vim
" :bprevious and :bnext
:VimproviserMap Buffers
" @h and @l -- improvise away!
:VimproviserMap Macros
" h and l -- boooring
:VimproviserMap Characters
```

Use `<c-d>` (`:h cmdline-completion`) to see all available options.

Read the comprehensive documentation in `:h vimproviser`.
