" Vim indent file
" Language:    OCaml
" Maintainer:  David Baelde <firstname.name@ens-lyon.org>
" Last Change: 2005 Mar 01
" Changelog:
"              - ExprBackward isn't bothered anymore by comments at the 
"                beginning of an expr
"              - Support for builtin "^"
"              - Much more customization
"              - (Almost) fully flexible indentation (not "strict" anymore)
"              - Major bug with sum types definition was corrected, and
"                polymorphic variants support added, -- thanks Zack !
"              - Added option "ocaml_noindent_let", many fixes -- thanks to
"                Pierre Habouzit !
"              - Bug with indentation after <fun> (s:blockstop+=<fun>)
"              - Second loading did nothing interesting, now corrected.
"              - Indentation of and in let definitions
"              - Syntax highlighting is turned on, cause I rely on synIDs
"              - Indentation of ";;" and correction of a bug related to
"                variables names beginning with "let" -- thanks to micha !
"              - Toplevel "let" definitions after end of modules/classes
"              - Corrected a bug related with garbage-eating operators
"                (let-in does that, if-then doesn't)
"              - Better mangement of "&&", "||" and ","
"              - Basic jumping now goes threw "::", "@", "<-" ... and correctly
"                goes back on for/while statements, and strings
"              - Corrected a few indent vs. col problems
"              - Added folding expression

" omlet.vim -- a set of files for working on OCaml code with VIm
" Copyright (C) 2005 David Baelde
"
" This program is free software; you can redistribute it and/or modify
" it under the terms of the GNU General Public License as published by
" the Free Software Foundation; either version 2 of the License, or
" (at your option) any later version.
"
" This program is distributed in the hope that it will be useful,
" but WITHOUT ANY WARRANTY; without even the implied warranty of
" MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
" GNU General Public License for more details.
"
" You should have received a copy of the GNU General Public License
" along with this program; if not, write to the Free Software
" Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

" TODO cannot re-indent when || is typed at begining of line
" TODO indentation is still strict for fun/arg and sequence
"      flexibility causes problems with patterns

" Only load this indent file when no other was loaded.
if exists("b:did_indent")
  finish
endif
let b:did_indent = 1

setlocal expandtab
setlocal comments=s1l:(*,mb:*,ex:*)
setlocal fo=croq
syntax enable
setlocal indentexpr=GetOMLetIndent(v:lnum)
setlocal indentkeys=0{,0},!^F,o,O,0=let\ ,0=and,0=in,0=end,0),o],0=do,0=done,0=then,0=else,0=with,0\|,0=->,0=;;,0=module,0=struct,0=sig,0=class,0=object,0=val,0=method,0=initializer,0=inherit,0=open,0=include,0=exception,0=external,0=type,0=&&,0^

" Do not define our functions twice
if exists("*GetOMLetIndent")
  finish
endif
let b:did_indent = 1

function s:default(s,v)
  if exists(a:s)
    exe "return" a:s
  else
    return a:v
  endif
endfunction

let s:i = s:default("g:omlet_indent",2)
let s:i_struct = s:default("g:omlet_indent_struct",s:i)
let s:i_match = s:default("g:omlet_indent_match",s:i)
let s:i_function = s:default("g:omlet_indent_function",s:i)
let s:i_let = s:default("g:omlet_indent_let",s:i)

" {{{ A few utils

function s:save()
  return line2byte(line('.'))+col('.')-1
endfunction

function s:restore(v)
  execute 'goto ' a:v
endfunction

" Same as searchpair() but skips comments and strings
function s:searchpair(beg,mid,end,flags)
  return searchpair(a:beg,a:mid,a:end,a:flags,'synIDattr(synID(line("."), col("."), 0), "name") =~? "string\\|comment"')
endfunction

" Same as search(_,'bW') but skips comments
function s:search(re)
  while search('\*)\_s*\%#','bW')
    call searchpair('(\*','','\*)','bW')
  endwhile
  return search(a:re,'bW')
endfunction

" Goes back to the beginning of an "end", whatever its opening keyword is
let s:begend = '\%(\<begin\>\|\<object\>\|\<struct\>\|\<sig\>\)'
function OMLetBegendBackward()
  return s:searchpair(s:begend,'','\<end\>','bW')
endfunction

" }}}

" {{{ Basic jumping
" Goes to the beginning of the previous (exclusive) block.
" It is stopped by any non-trivial syntax.
" The block moves are really the heart of omlet!

let s:blockstop = '\(\%^\|(\|{\|\[\|\<begin\>\|;\|,\|&&\|||\|\<try\>\|\<match\>\|\<with\>\||\|->\|\<when\>\|\<of\>\|\<fun\>\|\<function\>\|=\|\<let\>\|\<in\>\|\<for\>\|\<to\>\|\<do\>\|\<while\>\|\<if\>\|\<then\>\|\<else\>\|\<sig\>\|\<struct\>\|\<object\>\)\_s*\%#'

function OMLetAtomBackward()
  let s = s:save()

  if search('\*)\_s*\%#','bW')
    call searchpair('(\*','','\*)','bW')
    return OMLetAtomBackward()

  elseif search(')\_s*\%#','bW')
    return s:searchpair('(','',')','bW')

  elseif search('\]\_s*\%#','bW')
    return s:searchpair('\[','','\]','bW')

  elseif search('}\_s*\%#','bW')
    return s:searchpair('{','','}','bW')

  elseif search('"\_s*\%#','bW')
    while search('\_."','bW')
      if synIDattr(synID(line("."), col("."), 0), "name") != "ocamlString"
        call search('"')
        return 1
      endif
    endwhile
    throw "didn't find beginning of string"

  elseif search('\<done\>\_s*\%#','bW')
    call s:searchpair('\<do\>','','\<done\>','bW')
    return s:searchpair('\%(\<while\>\|\<for\>\)','','\<do\>','bW')

  elseif search('\<end\>\_s*\%#','bW')
    if synIDattr(synID(line("."), col("."), 0), "name") == "ocamlKeyword"
      call s:searchpair('\<begin\>','','\<end\>','bW')
      return 1
    else
      call s:restore(s)
    endif

  elseif search('\%(::\|`\|\.\|<-\|:=\|@\)\_s*\%#','bW')
    return OMLetAtomBackward()

  elseif search('=\_s*\%#','bW')
    if search('\%(\<let\>\|\<val\>\|\<method\>\|\<type\>\)[^=]\+\%#','bW')
      call s:restore(s)
    else
      return 1
    endif
  endif

  if search(s:blockstop,'bW')
    " Stop moving in front of those block delimiters
    call s:restore(s)
    return 0

  else
    " Otherwise, move backward, skipping an atom
    return search('\<','bW')
  endif
endfunction

function OMLetAtomsBackward()
  while OMLetAtomBackward()
  endwhile
endfunction

" }}}

" {{{ Complex jumping
" We still have problems with let, match, and else,
" which have no closing keyword.

function OMLetMatchHeadBackward()
  if search('\<with\>\_s*\%#','bW')
    call s:searchpair('\%(\<try\>\|\<match\>\)','','\<with\>','bW')
    return 1
  elseif search('\<fun\>\_s*\%#','bW')
    return 1
  elseif search('\<function\>\_s*\%#','bW')
    return 1
  elseif search('\<type\>\_[^=]\+=\_s*\%#','bW')
    return 1
  else
    return 0
  endif
endfunction

function OMLetIfHeadBackward()
  if search('\<then\_s*\%#','bW')
    call s:searchpair('\<if\>','','\<then\>','bW')
  else
    throw "Indentation failed!"
  endif
endfunction

function OMLetExprBackward(lf,gbg)
  if (a:lf != 'then' || a:gbg) && search('\<then\_s*\%#','bW')
    call s:searchpair('\<if\>','','\<then\>','bW')
    call OMLetExprBackward(a:lf,a:gbg)
    return 1

  elseif search('\<else\_s*\%#','bW')
    call OMLetBlockBackward('then',0)
    call OMLetIfHeadBackward()
    call OMLetExprBackward(a:lf,a:gbg)
    return 1

  " These operators have priority on ';' so we must skip them.
  " However, it is a bad programming style to use them at toplevel
  " in a sequence: ignore should be around.
  elseif search('\%(||\|&&\)\_s*\%#','bW')
    call OMLetExprBackward(a:lf,a:gbg)
    return 1

  elseif OMLetAtomBackward()
    call OMLetAtomsBackward()
    call OMLetExprBackward(a:lf,a:gbg)
    while searchpair('(\*','','\*)')
      " Go to the real end of comment, then to the next meaningful point
      call search(')')
      call search('\w')
    endwhile
    return 1

  else
    return 0
  endif
endfunction

" Now we include let and match...
" BlockBackward return 1 iff it succeeds in moving backward
" that's not a very strong specification :-/
function OMLetBlockBackward(lf,gbg)
  if OMLetExprBackward(a:lf,a:gbg) " Doesn't move the point on failure
    call OMLetBlockBackward(a:lf,a:gbg)
    return 1

  elseif search('\<in\>\_s*\%#','bW')
    call s:searchpair('\<let\>','','\<in\>','bW')
    call OMLetBlockBackward(a:lf, 0) " [let ... in] eats the garbage
    return 1

  elseif search('[;,]\_s*\%#','bW')
    call OMLetBlockBackward(a:lf,1) " sequence is the garbage
    return 1

  elseif search('\<when\_s*\%#','bW')
    call OMLetBlockBackward(a:lf,0)
    return 1

  elseif search('\%(->\|\<of\>\)\_s*\%#','bW')
    call OMLetPatternBackward()
    call OMLetBlockBackward('match',0)
    if a:lf != 'match'
      call OMLetMatchHeadBackward()
      call OMLetBlockBackward(a:lf,0) " match has eaten the garbage
    endif
    return 1

  endif
  return 0
endfunction

function OMLetPatternBackward()
  call OMLetBlockBackward('',0)
  call search('|\_s*\%#','bW') " allow failure
endfunction

" }}}

" {{{ Indentation function
" The goal is to return a 'correct' indentation,
" assuming that the previous lines are well indented.
" The optionnal argument avoids ignoring leading "| "

function s:indent(...)
  if search('[(\[{].*\%#','bW')
    call search('\S')
    return col('.')-1
  elseif a:0 && search('^\s*|.*\%#','bW')
    call search('\S')
    return col('.')-1
  else
    return indent('.')
  endif
endfunction

function GetOMLetIndent(l)

  " Go to the first non-blank char on the line to be indented.
  exe a:l

  " Indentation inside comments -- needs the comment to be closed!
  " TODO something weird is happening when inserting \n before ending *)
  if synIDattr(synID(line("."), col("."), 0), "name") =~? 'comment'
    let s = s:save()
    " TODO The next analysis should avoid strings
    call searchpair('(\*','','\*)','bW')
    if s != s:save()
      " We were strictly inside the comment, and we are now at its beginning
      call search('\*[^\*]')
      return col('.')-1
    endif
    " No need to restore, there was no move
  endif

  " Comments with a blank line before them are indented as the next block
  " This can be done only when the comment is closed
  if getline(a:l) =~ '^\s*(\*' && getline(a:l-1) =~ '^\s*$'
    call searchpair('(\*','','\*)')
    let new = nextnonblank(line('.')+1)
    if new == a:l
      return 0
    else
      return GetOMLetIndent(new)
    endif
  endif

  " {{{ Keyword alignments
  " How to indent a line starting with a keyword

  " Parenthesis-like closing

  if getline(a:l) =~ '^\s*\<end\>'
    call s:searchpair(s:begend,'','\<end\>','bW')
    return s:indent()
  endif

  if getline(a:l) =~ '^\s*}'
    call s:searchpair('{','','}','bW')
    return s:indent()
  endif

  if getline(a:l) =~ '^\s*)'
    call s:searchpair('(','',')','bW')
    return s:indent()
  endif

  if getline(a:l) =~ '^\s*\]'
    call s:searchpair('\[','','\]','bW')
    return s:indent()
  endif

  " WHILE and FOR

  if getline(a:l) =~ '^\s*\<done\>'
    call s:searchpair('\<do\>','','\<done\>','bW')
    call s:searchpair('\%(\<while\>\|\<for\>\)','','\<do\>','bW')
    return s:indent()
  endif

  if getline(a:l) =~ '^\s*\<do\>'
    call s:searchpair('\<\(while\|for\)\>','','\<do\>','bW')
    return s:indent()
  endif

  " PATTERNS

  " I want 'with' to be stricly aligned on 'match'
  " since I align patterns on 'match'
  if getline(a:l) =~ '^\s*with\>'
    call s:searchpair('\%(\<try\>\|\<match\>\)','','\<with\>','bW')
    return s:indent()
  endif

  if getline(a:l) =~ '^\s*->'
    call OMLetPatternBackward()
    return s:indent()+s:i
  endif

  " IF/THEN/ELSE

  if getline(a:l) =~ '^\s*\<then\>'
    call s:searchpair('\<if\>','','\<then\>','bW')
    return s:indent()
  endif

  if getline(a:l) =~ '^\s*else\>'
    call OMLetBlockBackward('then',0)
    if s:search('\<then\_s*\%#')
      call s:searchpair('\<if\>','','\<then\>','bW')
    endif
    return s:indent()
  endif

  " ;; alone is indented as toplevel defs
  if getline(a:l) =~ '^\s*;;'
    if OMLetBegendBackward()
      return s:indent()+s:i_struct
    else
      return 0
    endif
  endif

  " { and [ may need to be reindented in type definitions, where they don't
  " really deserve the default +4 indentation
  " if getline(a:l) =~ '^\s*{'
  "   return s:indent(a:l-1)+2 " TODO that's weak !
  " endif

  " Easy toplevel definitions
  if getline(a:l) =~ '^\s*\%(\<open\>\|\<include\>\|\<struct\>\|\<object\>\|\<sig\>\|\<val\>\|\<module\>\|\<class\>\|\<type\>\|\<method\>\|\<initializer\>\|\<inherit\>\|\<exception\>\|\<external\>\)'
    if s:searchpair(s:begend,'','\<end\>','bW')
      return s:indent()+s:i_struct
    else
      return 0
    endif
  endif

  " The next three tests are for indenting toplevel let

  " let after a high-level end (not matching a begin)
  if getline(a:l) =~ '^\s*let\>' && s:search('\<end\>\_s*\%#') && synIDattr(synID(line('.'),col('.'),0),'name') != 'ocamlKeyword'
    call OMLetBegendBackward()
    return s:indent()
  else
    exe a:l
  endif

  " let at the beginning of a structure
  if getline(a:l) =~ '^\s*let\>' && s:search('\<struct\>\_s*\%#')
    return s:indent()+s:i_struct
  endif

  " let after another value-level construct
  if getline(a:l) =~ '^\s*let\>' && (OMLetAtomBackward() || search(';;\_s*\%#'))
    if OMLetBegendBackward()
      return s:indent()+s:i_struct
    else
      return 0
    endif
  else
    exe a:l
    " That was undoing the AtomBackward
  endif

  " let/and
  if getline(a:l) =~ '^\s*and\>' && OMLetBlockBackward('',0)
    if s:search('\%(\<let\>\|\<and\>\)\_[^=]\+=\_s*\%#')
      return s:indent()
    else
      exe a:l
    endif
  endif

  " Now we deal with let/in
  if getline(a:l) =~ '^\s*in\>'
    call s:searchpair('\<let\>','','\<in\>','bW')
    return s:indent()
  endif

  " let after let isn't indented
  if getline(a:l) =~ '^\s*\<let\>' && s:search('\<in\>\_s*\%#')
    call s:searchpair('\<let\>','','\<in\>','bW')
    return s:indent()
  endif

  " &&, ||, and co.
  if getline(a:l) =~ '^\s*\%(||\|&&\|\^\)'
    call OMLetExprBackward('',0)
    return s:indent()
  endif

  " Matching clause marker |
  if getline(a:l) =~ '^\s*|'
    call OMLetBlockBackward('match',0)
    if s:search('|\_s*\%#')
      " We are stuck on a 0-ary constructor
      return s:indent(1)
    elseif s:search('\[\_s*\%#')
      " Polymorphic variant
      return col(".")-1
    elseif s:search('function\_s*\%#')
      return s:indent()+s:i_function
    else
      call OMLetMatchHeadBackward()
      return s:indent()+s:i_match
    endif
  endif

  " }}}

  " {{{ Beginning of blocks
  " Howto indent a line after some keyword

  " Basic case
  if s:search('\(\<struct\>\|\<sig\>\|\<class\>\)\_s*\%#')
    return s:indent()+s:i_struct
  endif
  if s:search('\(\<begin\>\|\<match\>\|\<try\>\|(\|{\|\[\|\<initializer\>\)\_s*\%#')
    return s:indent()+s:i
  endif
  if s:search('\%(\<let\>\|\<and\>\|\<module\>\|\<val\>\|\<method\>\)\_[^=]\+=\_s*\%#')
    return s:indent()+s:i
  endif

  " PATTERNS
  if s:search('\<function\>\_s*\%#')
    return s:indent()+2+s:i_function
  endif
  if s:search('\<with\>\_s*\%#')
    call s:searchpair('\%(\<match\>\|\<try\>\)','','\<with\>','bW')
    return s:indent()+2+s:i_match
  endif
  if s:search('\<type\>\_[^=]\+=\_s*\%#')
    return s:indent()+2+s:i
  endif
  if s:search('\<of\>\_s*\%#')
    return s:indent()+s:i
  endif

  " Sometimes you increment according to a master keyword

  " IF
  if s:search('\<if\>\_s*\%#')
    return s:indent()+s:i
  endif
  if s:search('\<then\>\_s*\%#')
    call s:searchpair('\<if\>','','\<then\>','bW')
    return s:indent()+s:i
  endif
  if s:search('\<else\_s*\%#')
    call OMLetBlockBackward('then',0)
    call OMLetIfHeadBackward()
    return s:indent()+s:i
  endif

  " MATCH
  if s:search('\<when\_s*\%#')
    call OMLetPatternBackward()
    return s:indent()+s:i
  endif
  if s:search('->\_s*\%#')
    call OMLetPatternBackward()
    call OMLetBlockBackward('match',0)
    call OMLetMatchHeadBackward()
    if search('\%#fun\>')
      return s:indent()+s:i
    elseif search('\%#function\>')
      return s:indent()+2+s:i+s:i_function
    else
      return s:indent()+2+s:i+s:i_match
    endif
  endif

  " WHILE/DO
  if s:search('\<do\>\_s*\%#')
    call s:searchpair('\%(\<while\>\|\<for\>\)','','\<do\>','bW')
    return s:indent()+s:i
  endif

  " LET
  if s:search('\<in\>\_s*\%#')
    call s:searchpair('\<let\>','','\<in\>','bW')
    return s:indent()+s:i_let
  endif

  " }}}

  " Sequence: find previous instruction's base indentation

  if s:search(';;\_s*\%#')
    if OMLetBegendBackward()
      return s:indent()+s:i_struct
    else
      return 0
    endif
  endif

  if s:search('\%(;\|,\|\^\|||\|&&\)\_s*\%#')
    " TODO here I could be a bit more flexible...
    call OMLetExprBackward('',0)
    return col(".")-1
  endif

  " Application: indentation between a function and its arguments

  if OMLetAtomBackward()
    " TODO flexible indentation
    call OMLetAtomsBackward()
    return col('.')-1+s:i
  else
    return 0
  endif

endfunction

" }}}
