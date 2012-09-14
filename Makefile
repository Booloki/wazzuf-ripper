SHELL = /bin/sh

sysconfdir_prefix = /etc
prefix = /usr
datarootdir = $(prefix)/share
exec_prefix = $(prefix)
MKINSTALLDIRS = mkdir -p
INSTALL = cp

sysconfdir = $(sysconfdir_prefix)/wazzuf-ripper
bindir = $(exec_prefix)/bin
libdir = $(exec_prefix)/lib/wazzuf-ripper
docdir = $(datarootdir)/doc/wazzuf-ripper
datadir = $(datarootdir)/wazzuf-ripper
templatesdir = $(datadir)/tag-templates

installdirs: 
	$(MKINSTALLDIRS) \
	$(DESTDIR)$(bindir) $(DESTDIR)$(templatesdir) \
	$(DESTDIR)$(libdir) $(DESTDIR)$(sysconfdir) \
	$(DESTDIR)$(docdir) 

install: installdirs 
	$(NORMAL_INSTALL)
		$(INSTALL) scripts/* $(DESTDIR)$(bindir)/
		$(INSTALL) functions/* $(DESTDIR)$(libdir)/
		$(INSTALL) tag-templates/* $(DESTDIR)$(templatesdir)/
		$(INSTALL) conf/wazzuf-path.conf $(DESTDIR)$(sysconfdir)/
		$(INSTALL) conf/wazzuf-ripper.conf $(DESTDIR)$(datadir)/
		$(INSTALL) doc/* $(DESTDIR)$(docdir)/
