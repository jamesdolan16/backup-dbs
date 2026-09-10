PREFIX ?= /usr/local

build:
	sbcl --non-interactive --load build.lisp

install: build
	install -Dm755 backup-dbs $(DESTDIR)$(PREFIX)/bin/backup-dbs

uninstall:
	rm -f $(DESTDIR)$(PREFIX)/bin/backup-dbs
