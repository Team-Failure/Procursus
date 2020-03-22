ifneq ($(CHECKRA1N_MEMO),1)
$(error Use the main Makefile)
endif

COREUTILS_VERSION := 8.31
DEB_COREUTILS_V   ?= $(COREUTILS_VERSION)

# `gl_cv_func_ftello_works=yes` workaround for gnulib issue on macOS Catalina, presumably also
# iOS 13, borrowed from Homebrew formula for coreutils
# TODO: Remove when GNU fixes this issue

ifneq ($(wildcard $(BUILD_WORK)/coreutils/.build_complete),)
coreutils:
	@echo "Using previously built coreutils."
else
coreutils: setup
	mkdir -p $(BUILD_WORK)/coreutils/su
	wget -nc -P $(BUILD_WORK)/coreutils/su \
		https://raw.githubusercontent.com/coolstar/netbsd-ports-ios/trunk/usr.bin/su/su.c \
		https://raw.githubusercontent.com/coolstar/netbsd-ports-ios/trunk/usr.bin/su/suutil.{c,h}
	cd $(BUILD_WORK)/coreutils/su && $(CC) $(CFLAGS) su.c suutil.c -o su -DBSD4_4
	cd $(BUILD_WORK)/coreutils && ./configure -C \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=/usr \
		--without-gmp \
		gl_cv_func_ftello_works=yes
	$(MAKE) -C $(BUILD_WORK)/coreutils
	$(FAKEROOT) $(MAKE) -C $(BUILD_WORK)/coreutils install \
		DESTDIR=$(BUILD_STAGE)/coreutils
	cp $(BUILD_WORK)/coreutils/su/su $(BUILD_STAGE)/coreutils/usr/bin
	touch $(BUILD_WORK)/coreutils/.build_complete
endif

coreutils-stage: coreutils
	# coreutils.mk Package Structure
	rm -rf $(BUILD_DIST)/coreutils
	mkdir -p $(BUILD_DIST)/coreutils/{etc/profile.d,bin,usr/sbin}
	
	# coreutils.mk Prep coreutils
	cp -a $(BUILD_STAGE)/coreutils/usr $(BUILD_DIST)/coreutils
	ln -s /usr/bin/chown $(BUILD_DIST)/coreutils/usr/sbin
	ln -s /usr/bin/chown $(BUILD_DIST)/coreutils/bin
	ln -s /usr/bin/chroot $(BUILD_DIST)/coreutils/usr/sbin
	ln -s /usr/bin/{cat,chgrp,cp,date,dd,dir,echo,false,kill,ln,ls,mkdir,mknod,mktemp,mv,pwd,readlink,rm,rmdir,sleep,stty,su,touch,true,uname,vdir} $(BUILD_DIST)/coreutils/bin
	cp $(BUILD_INFO)/coreutils.sh $(BUILD_DIST)/coreutils/etc/profile.d

	# coreutils.mk Sign
	$(call SIGN,coreutils,general.xml)
	
	# coreutils.mk Make .debs
	$(call PACK,coreutils,DEB_COREUTILS_V)
	
	# coreutils.mk Build cleanup
	rm -rf $(BUILD_DIST)/coreutils

.PHONY: coreutils coreutils-stage
