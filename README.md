# vim-illuminate

Vim plugin for selectively illuminating other uses of the current word under the cursor

![gif](https://media.giphy.com/media/ZO7QtQWoBP2TZ9mkXq/giphy.gif)

## Rational

All modern IDEs and editors will highlight the word under the cursor which is a great way to see other uses of the current variable without having to look for it.

## About

This plugin is a tool for illuminating the other uses of the current word under the cursor.

Illuminate will by default highlight all uses of the word under the cursor, but with a little bit of configuration it can easily only highlight what you want it to highlight based on the filetype and highlight-groups.

Illuminate will also do a few other niceties such as delaying the highlight for a user-defined amount of time based on `g:Illuminate_delay` (by default 250), it will interact nicely with search highlighting, jumping around between buffers, jumping around between windows, and won't illuminate while in insert mode.

This script is modified version of RRethy's plugin: https://github.com/RRethy/vim-illuminate. Orginal version is good enough for most users. This plugin modifies some features and adds additional prefix support. Prefix support means that word match is determined with predefinied regular expression. Modified version adds also modes, that can be used in case of missing timer.

## Configuration

Illuminate will delay before highlighting, this is not lag, it is to avoid the jarring experience of things illuminating too fast. This can be controlled with `g:Illuminate_delay` (which is default to 250 milliseconds):

**Note**: Delay only works for Vim8 and Neovim.

```
" Time in milliseconds (default 250)
let g:Illuminate_delay = 250
```
Illuminate will by default highlight the word under the cursor to match the behaviour seen in Intellij and VSCode. However, to make it not highlight the word under the cursor, use the following:

```
" Don't highlight word under cursor (default: 1)
let g:Illuminate_highlightUnderCursor = 0
```

By default illuminate will highlight all words the cursor passes over, but for many languages, you will only want to highlight certain highlight-groups (you can determine the highlight-group of a symbol under your cursor with `:echo synIDattr(synIDtrans(synID(line("."), col("."), 1)), "name")`).

You can define which highlight groups you want the illuminating to apply to. This can be done with a dict mapping a filetype to a list of highlight-groups in your vimrc such as:
```
let g:Illuminate_ftHighlightGroups = {
      \ 'vim': ['vimVar', 'vimString', 'vimLineComment',
      \         'vimFuncName', 'vimFunction', 'vimUserFunc', 'vimFunc']
      \ }
```


illuminate can also be disabled for various filetypes using the following:
```
let g:Illuminate_ftblacklist = ['nerdtree']
```

Lastly, by default the highlighting will be done with the hl-group `CursorLine` since that is in my opinion the nicest. It can however be overridden using the following or something similar:
```
hi illuminatedWord cterm=underline gui=underline
```

Illumination can be triggered with 3 modes. Mode determines how to trigger illumination. Default mode 0 means automatic feature detection. Value 1 forces timer usage. Value 2 forces illuminating only if delay between cursor moves is larger than predefinied threshold - `g:Illuminate_reltime_delay`. Value 3 cases that illumination is triggered as soon as cursor moves.
```
" forces measurement between cursor moves
let g:Illuminate_mode = 2
```

To customize duration in mode with value 2 use following setting:
```
" duration in seconds
let g:Illuminate_reltime_delay = 0.8
```

Illumination can use prefixes patterns. To enable this behaviour apply this setting:
```
let g:Illuminate_use_prefix_pattern = 1
```

To define pattern use buffer variable. For example for prefix `'\(m_\|l_\|c_\)'` holding cursor on `l_word` causes illumination of `word` part in occurences of `l_word`, `m_word`, `c_word`. Note that this applies to current buffer.
```
let b:Illuminate_prefix_pattern = '\(\m_\|l_\|c_\)'
```

To define prefix for some filetype use following command:
```
autocmd BufReadPost,BufNewFile *.filetype let b:Illuminate_prefix_pattern = '\(\w_\)'
```


## Installation

This assumes you have the packages feature. If not, any plugin manager will suffice.

### Neovim

```
mkdir -p ~/.config/nvim/pack/plugins/start
cd ~/.config/nvim/pack/plugins/start
git clone https://github.com/Khadmium/vim-illuminate.git
```

### Vim

```
mkdir -p ~/.vim/pack/plugins/start
cd ~/.vim/pack/plugins/start
git clone https://github.com/Khadmium/vim-illuminate.git
```

## FAQs

> I am seeing by default an underline for the matched words

Try this: `hi link illuminatedWord Visual`. The reason for the underline is that the highlighting is done with `CursorLine` by default, which defaults to an underline.
