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
iconsdir = $(datarootdir)/pixmaps
desktopdir = $(datarootdir)/applications
localedir = $(datarootdir)/locale
manpagesdir1= $(datarootdir)/man/man1
manpagesdir4= $(datarootdir)/man/man4
templatesdir = $(datadir)/tag-templates

installdirs: 
	$(MKINSTALLDIRS) \
	$(DESTDIR)$(bindir) $(DESTDIR)$(templatesdir) \
	$(DESTDIR)$(libdir) $(DESTDIR)$(sysconfdir) \
	$(DESTDIR)$(docdir) $(DESTDIR)$(manpagesdir1) \
	$(DESTDIR)$(manpagesdir4) $(DESTDIR)$(desktopdir) \
	$(DESTDIR)$(localedir) $(DESTDIR)$(iconsdir)

install: installdirs 
	$(NORMAL_INSTALL)
		$(INSTALL) scripts/* $(DESTDIR)$(bindir)/
		$(INSTALL) functions/* $(DESTDIR)$(libdir)/
		$(INSTALL) tag-templates/* $(DESTDIR)$(templatesdir)/
		$(INSTALL) conf/wazzuf-ripper-global.conf $(DESTDIR)$(sysconfdir)/
		$(INSTALL) conf/wazzuf-ripper.conf $(DESTDIR)$(datadir)/
		$(INSTALL) doc/* $(DESTDIR)$(docdir)/
		$(INSTALL) manpages/man1/* $(DESTDIR)$(manpagesdir1)/
		$(INSTALL) manpages/man4/* $(DESTDIR)$(manpagesdir4)/
		$(INSTALL) gui/desktop/* $(DESTDIR)$(desktopdir)/
		$(INSTALL) gui/icons/* $(DESTDIR)$(iconsdir)/
		$(INSTALL) fr/LC_MESSAGES/* $(DESTDIR)$(iconsdir)/fr/LC_MESSAGES/
