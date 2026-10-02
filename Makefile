PREFIX ?= /usr/local
BINDIR = $(PREFIX)/bin
LIBDIR = $(PREFIX)/share/gitriage

.PHONY: install uninstall test lint

install:
	install -d $(DESTDIR)$(BINDIR)
	install -d $(DESTDIR)$(LIBDIR)
	install -m 755 gitriage.sh     $(DESTDIR)$(LIBDIR)/
	install -m 644 gitriage.lib.sh $(DESTDIR)$(LIBDIR)/
	install -m 644 report.css      $(DESTDIR)$(LIBDIR)/
	ln -sf $(LIBDIR)/gitriage.sh   $(DESTDIR)$(BINDIR)/gitriage

uninstall:
	rm -f $(DESTDIR)$(BINDIR)/gitriage
	rm -rf $(DESTDIR)$(LIBDIR)

lint:
	shellcheck gitriage.sh gitriage.lib.sh

test:
	./gitriage.sh --dir . --format text
	./gitriage.sh --dir . --format json  > /dev/null
	./gitriage.sh --dir . --format csv   > /dev/null
	./gitriage.sh --dir . --format markdown > /dev/null
