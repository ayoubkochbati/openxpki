## Written 2006 by Martin Bartosch for the OpenXPKI project
## Copyright (C) 2005-2011 by The OpenXPKI Project

TOPDIR=../../..

PACKAGE=perl-openxpki-client-enrollment
SRCBASE=$(TOPDIR)/clients/perl/OpenXPKI-Client-Enrollment
SRCNAME=OpenXPKI-Client-Enrollment

# Makefile.inc contains common settings for all packages (checked in)
include ../Makefile.inc
# Makefile.local may be used locally to override settings (not checked in)
-include ../Makefile.local

all: clean perl-dist package collect

dist-clean:
	( cd $(SRCBASE) && \
		rm -f *.tar.gz \
	)


perl-dist: dist-clean
	cd $(SRCBASE) && perl Makefile.PL
	cd $(SRCBASE) && make dist
	mkdir -p $(RPMBASE)/SOURCES
	ls -l $(SRCBASE)/*.tar.gz
	mv $(SRCBASE)/*.tar.gz $(RPMBASE)/SOURCES

$(PACKAGE).spec: $(PACKAGE).spec.template

package: $(PACKAGE).spec
	PERL_LOCAL_LIB_ROOT= PERL_MB_OPT= PERL_MM_OPT= rpmbuild -ba $(PACKAGE).spec

collect:
	mv $(RPMBASE)/SRPMS/$(PACKAGE)-*.rpm .
	mv $(RPMBASE)/RPMS/*/$(PACKAGE)-*.rpm .

clean:
	rm -f $(PACKAGE)-*.rpm $(PACKAGE).spec


