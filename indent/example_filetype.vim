if exists("did_load_filetypes")
  finish
endif

augroup filetypedetect
  au! BufRead,BufNewFile *.ml,*.mli setfiletype omlet
augroup END
                                                           
