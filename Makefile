.PHONY: install dist

VERSION=0.13

install:
	BASE=$(HOME)/.vim make install-aux
install-sys:
	BASE=/usr/share/vim/vimfiles make install-aux

install-aux:
	for i in indent syntax ftplugin ftdetect ; do \
	  mkdir -p $(BASE)/$$i ; \
	  cp -f $$i/omlet.vim $(BASE)/$$i ; \
	done
	@echo Installation done.
	@echo
	@echo Add lines like \"filetype plugin on\", \"filetype indent on\" to your .vimrc
	@echo in order to enable OMLet.
	@echo See README for other useful information.

V=omlet-$(shell date +%y%m%d)
D=/home/httpd/htdocs/david.baelde/productions/POOL

dist:
	rm -rf omlet-$(VERSION)
	mkdir omlet-$(VERSION)
	cp LICENSE README INSTALL ChangeLog Makefile omlet-$(VERSION)
	for i in indent syntax ftplugin ftdetect ; do \
		mkdir omlet-$(VERSION)/$$i ; \
		cp $$i/omlet.vim omlet-$(VERSION)/$$i ; \
	done
	tar czvf $(V).tar.gz omlet-$(VERSION)
	rm -rf omlet-$(VERSION)
	cp $(V).tar.gz omlet-$(VERSION).tar.gz
