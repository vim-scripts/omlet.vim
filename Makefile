.PHONY: install dist

install:
	mkdir -p $(HOME)/.vim/indent
	mkdir -p $(HOME)/.vim/syntax
	mkdir -p $(HOME)/.vim/ftplugin
	cp -f indent/omlet.vim $(HOME)/.vim/indent
	cp -f syntax/omlet.vim $(HOME)/.vim/syntax
	cp -f ftplugin/omlet.vim $(HOME)/.vim/ftplugin
	@echo Installation done.
	@echo
	@if test -e $(HOME)/.vim/filetype.vim ; then \
		echo Please add the contents of example_filetype.vim to $(HOME)/.vim/filetype.vim ; \
	else \
		echo Creating filetype.vim... ; \
		cp -f example_filetype.vim $(HOME)/.vim/filetype.vim ; \
	fi
	@cat README

V=omlet-$(shell date +%y%m%d)
D=/home/httpd/htdocs/david.baelde/productions/POOL

dist:
	rm -rf $(V)
	mkdir $(V)
	cp LICENSE README INSTALL Makefile example_filetype.vim $(V)
	for i in indent syntax ftplugin ; do \
		mkdir $(V)/$$i ; \
		cp $$i/omlet.vim $(V)/$$i ; \
	done
	tar czvf $(V).tar.gz $(V)
	rm -rf $(V)
	cp $(V).tar.gz omlet.tar.gz
