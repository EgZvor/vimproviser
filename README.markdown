# Vimproviser

Vimproviser was designed to repeat motions.

Vimproviser provides commands and mappings that allow for a quick remapping of
two of your most convenient keys to actions that are most important for you
right now.

## Quick start

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

### Triggers

Triggers are just actions connected to some pair.
`VimproviserLast`
will perform an equivalent of
`VimproviserMap Pair`
for the last pair that was triggered.
Define a bunch of triggers for pairs:

``` vim
let g:vimproviser_triggers = {
\    'Changes': ['g;', 'g,'],
\    'Characters': ['<left>', '<right>'],
\    'Macros': ['@h', '@l'],
\}
```

Now imagine you need to go deep into the changes you made recently,
hit `g;` as usual,
then `VimproviserLast`,
now you can use `h` and `l` to go back and forth.

Read the documentation in `:h vimproviser-quick-start`.

## Video showcase

<p align="center">
   <a href="https://www.youtube.com/watch?v=hnEEGPZeqFg">
   <img
      src="https://img.youtube.com/vi/hnEEGPZeqFg/0.jpg"
      alt="Thumbnail of a video with the text saying Vimprovise, adapt, overcome. Vim logo is placed on top of the beginning of the first word. There are gray rocks in the background."
      >
   </img>
   </a>
</p>

## Other plugins

Vimproviser is partly inspired by [unimpaired.vim](https://github.com/tpope/vim-unimpaired). They work together nicely!
