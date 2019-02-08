" illuminate.vim - Vim plugin for selectively illuminating other uses of current word
" Maintainer:	Adam P. Regasz-Rethy (RRethy) <rethy.spud@gmail.com>
" Version: 0.4

" Some local variables {{{
let s:match_id = 1867
let s:priority = -1
let s:previous_match = ''
let s:enabled = 1
" }}}

" Global variables init {{{
let g:Illuminate_delay = get(g:, 'Illuminate_delay', 250)
let g:Illuminate_highlightUnderCursor = get(g:, 'Illuminate_highlightUnderCursor', 1)
let g:Illuminate_mode = get(g:, 'Illuminate_mode', 0)
let g:Illuminate_reltime_delay = get(g:, 'Illuminate_reltime_delay', (1.0 * g:Illuminate_delay)/1000.0)
let g:Illuminate_use_prefix_patterns = 0
" }}}

" Exposed functions {{{
fun! illuminate#on_cursor_moved() abort
  if !s:should_illuminate_file()
    return
  endif
  let cur_word = s:get_cur_word()
  if (s:previous_match != cur_word)
    call s:remove_illumination()
  else
    return
  endif
  call s:illuminate_delay_implementation(cur_word)
endf

fun! s:illuminate_delay_implementation_timer(word) abort
  if g:Illuminate_delay < 17
    call s:illuminate(a:word)
    return
  endif
  if exists('s:timer_id') && s:timer_id > -1
    call timer_stop(s:timer_id)
  endif
  let s:timer_id = timer_start(g:Illuminate_delay, funcref('s:illuminate_with_curr_word'))
endf

fun! s:illuminate_with_curr_word() abort
  call s:illuminate(s:get_cur_word())
endf

fun! s:illuminate_delay_implementation_reltime(word) abort
  curr_reltime_sec = reltimefloat(reltime())
  if !exists('s:reltime_sec')
    s:reltime_sec = curr_reltime_sec
    return
  endif
  if curr_reltime_sec - s:reltime_sec < g:Illuminate_reltime_delay
    s:reltime_sec = curr_reltime_sec
    return
  endif
  call s:illuminate(a:word)
  s:reltime_sec = curr_reltime_sec
endf

fun! s:illuminate_delay_implementation_fallback(word) abort
    call s:illuminate(a:word)
endf

if g:Illuminate_mode == 1
  let s:illuminate_delay_implementation = funcref('s:illuminate_delay_implementation_timer')
  let s:remove_illumination_implementation = funcref('s:remove_illumination_implementation_timer')
elseif g:Illuminate_mode == 2
  let s:illuminate_delay_implementation = funcref('s:illuminate_delay_implementation_reltime')
  let s:remove_illumination_implementation = funcref('s:remove_illumination_implementation_reltime')
elseif g:Illuminate_delay == 3
  let s:illuminate_delay_implementation = funcref('s:illuminate_delay_implementation_fallback')
  let s:remove_illumination_implementation = funcref('s:remove_illumination_implementation_fallback')
else
  if has('timer')
    let s:illuminate_delay_implementation = funcref('s:illuminate_delay_implementation_timer')
    let s:remove_illumination_implementation = funcref('s:remove_illumination_implementation_timer')
  elseif has('reltime')
    let s:illuminate_delay_implementation = funcref('s:illuminate_delay_implementation_reltime')
    let s:remove_illumination_implementation = funcref('s:remove_illumination_implementation_timer')
  else
    let s:illuminate_delay_implementation = funcref('s:illuminate_delay_implementation_fallback')
    let s:remove_illumination_implementation = funcref('s:remove_illumination_implementation_fallback')
  endif
end


fun! illuminate#on_leaving_autocmds() abort
  if s:should_illuminate_file()
    call s:remove_illumination()
  endif
endf

fun! illuminate#on_insert_entered() abort
  if s:should_illuminate_file()
    call s:remove_illumination()
  endif
endf

fun! illuminate#toggle_illumination() abort
  if !s:enabled
    call illuminate#enable_illumination()
  else
    call illuminate#disable_illumination()
  endif
endf

fun! illuminate#disable_illumination() abort
  let s:enabled = 0
  call s:remove_illumination()
endf

fun! illuminate#enable_illumination() abort
  let s:enabled = 1
  if s:should_illuminate_file()
    call s:illuminate(s:get_cur_word())
  endif
endf

" }}}

" Abstracted functions {{{
fun! s:illuminate(word) abort
  if !s:enabled
    return
  endif
  call s:remove_illumination()
  if a:word ==# ''
    return
  endif
  pattern = wrap_word_in_pattern(a:word)
  if exists('g:Illuminate_ftHighlightGroups') && has_key(g:Illuminate_ftHighlightGroups, &filetype)
    if index(g:Illuminate_ftHighlightGroups[&filetype], synIDattr(synIDtrans(synID(line('.'), col('.'), 1)), 'name')) >= 0
      call s:match_word(pattern)
    endif
  else
    call s:match_word(pattern)
  endif
  let s:previous_match = pattern
endf

fun! s:match_word(word) abort
  if g:Illuminate_highlightUnderCursor
    silent! call matchadd('illuminatedWord', '\V' . a:word, s:priority, s:match_id)
  else
    silent! call matchadd('illuminatedWord', '\V\(\k\*\%#\k\*\)\@\!\&' . a:word, s:priority, s:match_id)
  endif
endf

fun! s:get_cur_word() abort
  let line = getline('.')
  let col = col('.') - 1
  let word = expand('<cword>')
  if word ==# ''
    return word
  endif
  if match(strpart(line, col, 1), '\k') == -1
    let word = ''
  endif
  return word
endf

"  test only functions - used in unit testing mainly {{{
fun! illuminate#_get_cur_word() abort
  return s:get_cur_word()
endf

fun! illuminate#_wrap_word_in_pattern(word) abort
  return s:wrap_word_in_pattern(a:word)
endf
" }}}

fun! s:wrap_word_in_pattern(word) abort
  using_patterns = g:Illuminate_use_prefix_patterns
  patterns = get(b:, 'Illuminate_prefix_patterns', [])
  if using_patterns || empty(patterns)
    return '\v<' + a:word + '>'
  endif
  let pattern_str = '(' . join(patterns, '|') . ')'
  word = substitute(a:word, '\v<' . pattern_str, '')
  " returned pattern to match is like (with very-magic option)
  " (<(p1|p2|p3...))@<=part_of_word_to_match>
  return '\v(<' .  pattern_str . ')@<=' . word . '>'
endf

fun! s:remove_illumination() abort
  call s:remove_illumination_implementation()
endf

fun! s:remove_match() abort
  try
    call matchdelete(s:match_id)
  catch /\v(E803|E802)/
  endtry
  let s:previous_match = ''
endf

fun! s:remove_illumination_implementation_timer() abort
  call timer_stop(s:timer_id)
  let s:timer_id = -1
  call s:remove_match()
endf


fun! s:remove_illumination_implementation_fallback() abort
  call s:remove_match()
endf

fun! s:remove_illumination_implementation_reltime() abort
  unlet s:reltime_sec
  call s:remove_match()
endf

fun! s:should_illuminate_file() abort
  if !exists('g:Illuminate_ftblacklist')
    let g:Illuminate_ftblacklist=['']
  endif

  return index(g:Illuminate_ftblacklist, &filetype) < 0
endf
" }}}

" vim: foldlevel=1 foldmethod=marker
