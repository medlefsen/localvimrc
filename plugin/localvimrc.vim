" Name:    localvimrc.vim
" Version: $Id: localvimrc.vim 2758 2009-05-11 12:09:38Z mbr $
" Author:  Markus Braun
" Summary: Search local vimrc files and load them.
" Licence: This program is free software; you can redistribute it and/or
"          modify it under the terms of the GNU General Public License.
"          See http://www.gnu.org/copyleft/gpl.txt
" Section: Documentation {{{1
" Description:
"
"   This plugin searches for local vimrc files in the file system tree of the
"   currently opened file. By default it searches for all ".lvimrc" files from
"   the file's directory up to the root directory and loads them in reverse
"   order. The filename and amount of loaded files is customizable through
"   global variables.
"
" Installation:
"
"   Copy the localvimrc.vim file to the $HOME/.vim/plugin directory.
"   Refer to ':help add-plugin', ':help add-global-plugin' and ':help
"   runtimepath' for more details about Vim plugins.
"
" Variables:
"
"   g:localvimrc_name
"     Filename of local vimrc files.
"     Defaults to ".lvimrc".
"
"   g:localvimrc_count
"     On the way from root, the last localvimrc_count files are sourced.
"     Defaults to -1 (all)
"
"   g:localvimrc_sandbox
"     Source the found local vimrc files in a sandbox for security reasons.
"     Defaults to 1.
"
"   g:localvimrc_ask
"     Ask before sourcing any local vimrc file.
"     Defaults to 1.
"
"   g:localvimrc_trustfile
"     File to store trusted local vimrc paths.
"     Defaults to "$HOME/.localvimrc_trusted".
"
" Credits:
" - Simon Howard for his hint about "sandbox"
"
" Section: Plugin header {{{1
" guard against multiple loads {{{2
if (exists("g:loaded_localvimrc") || &cp)
  finish
endif
let g:loaded_localvimrc = "$Revision: 2758 $"

" check for correct vim version {{{2
if version < 700
  finish
endif

" define default local vimrc file name {{{2
if (!exists("g:localvimrc_name"))
  let g:localvimrc_name = ".lvimrc"
endif

" define default "search depth" {{{2
if (!exists("g:localvimrc_count"))
  let g:localvimrc_count = -1
endif

" define default for sandbox {{{2
if (!exists("g:localvimrc_sandbox"))
  let g:localvimrc_sandbox = 1
endif

" define default for asking {{{2
if (!exists("g:localvimrc_ask"))
  let g:localvimrc_ask = 1
endif

" define default for trustfile {{{2
if (!exists("g:localvimrc_trustfile"))
  let g:localvimrc_trustfile = $HOME . "/.localvimrc_trustfile"
endif

" Section: Functions {{{1
" Function: s:localvimrc {{{2
"
" search all local vimrc files from current directory up to root directory and
" source them in reverse order.
"
function! s:localvimrc()
  " directory of current file (correctly escaped)
  let l:directory = escape(expand("%:p:h"), ' ~|!"$%&()=?{[]}+*#'."'")

  " generate a list of all local vimrc files along path to root
  let l:rcfiles = findfile(g:localvimrc_name, l:directory . ";", -1)

  " shrink list of found files
  if g:localvimrc_count == -1
    let l:rcfiles = l:rcfiles[0:-1]
  elseif g:localvimrc_count == 0
    let l:rcfiles = []
  else
    let l:rcfiles = l:rcfiles[0:(g:localvimrc_count-1)]
  endif

  if filereadable(g:localvimrc_trustfile)
    exec "source  " . g:localvimrc_trustfile
  endif
  if !exists("g:localvimrc_trusted")
    let g:localvimrc_trusted = []
  endif

  " source all found local vimrc files along path from root (reverse order)
  let l:answer = ""
  for l:rcfile in reverse(l:rcfiles)
    if filereadable(l:rcfile)
      " ask if this rcfile should be loaded
      if l:rcfile =~ '^/'
        let l:rcpath = l:rcfile
      else
        let l:rcpath = simplify(getcwd() . '/' . l:rcfile)
      endif
      if (count(g:localvimrc_trusted,l:rcpath) == 0 && l:answer != "a")
        if (g:localvimrc_ask == 1)
          let l:message = "localvimrc: source " . l:rcpath . "?\n t[rust], y[es], n[o], a[ll], q[uit]> "
          let l:answer = input(l:message)
        else
          let l:answer = "a"
        endif
      endif

      if (l:answer =~ '^t\(rust\)\?$')
        call add(g:localvimrc_trusted,l:rcpath)
        exec "redir! > " . g:localvimrc_trustfile
        silent echo 'let g:localvimrc_trusted = ' . string(g:localvimrc_trusted)
        redir end
      endif

      " check the answer
      if (l:answer =~ '^y\(es\)\?$' || l:answer =~ '^a\(ll\)\?$' || l:answer =~ '^t\(rust\)\?$')

        " add 'sandbox' if requested
        if (g:localvimrc_sandbox != 0)
          let l:command = "sandbox "
        else
          let l:command = ""
        endif
        let l:command .= "source " . escape(l:rcfile, ' ~|!"$%&()=?{[]}+*#'."'")

        " execute the command
        exec l:command
        "echom "localvimrc: sourced " . l:rcfile

      elseif (l:answer == "q")
        break
      endif

    endif
  endfor

  " clear command line
  redraw!
endfunction

" Section: Autocmd setup {{{1
if has("autocmd")
  augroup localvimrc
    autocmd!
    " call s:localvimrc() when creating ore reading any file
    autocmd BufNewFile,BufRead * call s:localvimrc()
  augroup END
endif

" vim600: foldmethod=marker
