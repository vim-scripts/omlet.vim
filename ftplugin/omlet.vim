" Language:    OCaml
" Maintainer:  David Baelde <firstname.name@ens-lyon.org>
" Last Change: 2005 Feb 02

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

if exists("*OMLetFoldLevel")
  finish
endif

function s:topindent(lnum)
  let l = a:lnum
  while l > 0
    if getline(l) =~ '\s*\%(\<struct\>\|\<sig\>\|\<object\>\)'
      return indent(l)
    endif
    let l = l-1
  endwhile
  return 0
endfunction

function OMLetFoldLevel(l)

  " This is for not merging blank lines around folds to them
  if getline(a:l) !~ '\S'
    return -1
  endif

  " We start folds for modules, classes, and every toplevel definition
  if getline(a:l) =~ '^\s*\%(\<val\>\|\<module\>\|\<class\>\|\<type\>\|\<method\>\|\<initializer\>\|\<inherit\>\|\<exception\>\|\<external\>\)'
    exe 'return ">' (indent(a:l)/2)+1 '"'
  endif

  " Toplevel let are detected thanks to the indentation
  if getline(a:l) =~ '^\s*let\>' && indent(a:l) == 2+s:topindent(a:l)
    exe 'return ">' (indent(a:l)/2)+1 '"'
  endif

  " We close fold on end which are associated to struct, sig or object.
  " We use syntax information to do that.
  if getline(a:l) =~ '^\s*end\>' && synIDattr(synID(a:l, indent(a:l)+1, 0), "name") != "ocamlKeyword"
    return (indent(a:l)/2)+1
  endif

  " Comments around folds aren't merged to them.
  if synIDattr(synID(a:l, indent(a:l)+1, 0), "name") == "ocamlComment"
    return -1
  endif

  return '='
endfunction

set foldmethod=expr
set foldexpr=OMLetFoldLevel(v:lnum)

