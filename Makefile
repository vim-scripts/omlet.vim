install:
	mkdir -p ~/.vim/indent
	mkdir -p ~/.vim/syntax
	mkdir -p ~/.vim/ftplugin
	cp -f indent/omlet.vim ~/.vim/indent
	cp -f syntax/omlet.vim ~/.vim/ftplugin
	cp -f ftplugin/omlet.vim ~/.vim/ftplugin
	@echo Installation done.
	@echo
	@if test -e ~/.vim/filetype.vim ; then \
		echo Please add the contents of example_filetype.vim ; \
		echo to your ~/.vim/filetype.vim ; \
	else \
		echo Creating filetype.vim... ; \
		cp -f example_filetype.vim ~/.vim/filetype.vim ; \
	fi
	@echo
	@echo Please make sure that the following is included in your ~/.vimrc
	@echo ">>> filetype plugin indent on"
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
