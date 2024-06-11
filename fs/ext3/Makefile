ifndef CONFIG_EXT3_FS
	EXTERNAL_BUILD=y
	CONFIG_EXT3_FS=m
endif

obj-$(CONFIG_EXT3_FS) += ext3.o
ext3-y	:= balloc.o bitmap.o dir.o file.o fsync.o ialloc.o inode.o \
	ioctl.o namei.o super.o symlink.o hash.o resize.o ext3_jbd.o yuiha_buffer_head.o
ext3-$(CONFIG_EXT3_FS_XATTR)	 += xattr.o xattr_user.o xattr_trusted.o
ext3-$(CONFIG_EXT3_FS_POSIX_ACL) += acl.o
ext3-$(CONFIG_EXT3_FS_SECURITY)	 += xattr_security.o

list-$(CONFIG_EXT3_FS) += ext3

EXTRA_CFLAGS += -I ../../include

KVER := $(shell uname -r)
KSRC := /lib/modules/$(KVER)/build
MDIR := /lib/modules/$(KVER)/kernel/fs/ext3/
PWD := $(shell pwd)

PREINC := -I$(PWD)/../../include
EXTRA_CFLAGS += -Wall -g -O0

default:
	$(MAKE) -C $(KSRC) SUBDIRS=$(PWD) BUILD_DIR=$(PWD) \
	NOSTDINC_FLAGS=$(PREINC) modules

install: unload
	install -d $(MDIR)
	install -m 644 -c $(addsuffix .ko,$(list-m)) $(MDIR)
	/sbin/depmod $(KVER) -A

uninstall: unload
	rm -rf $(addprefix $(MDIR),$(addsuffix .ko,$(list-m)))
	/sbin/depmod $(KVER) -A

load:
	depmod -a
	modprobe -v ext3

unload:
	@test "`uname -r`" != "$(KVER)" || \
	     if [ -n "`mount -t $(list-m)`" ]; then \
	         echo "Unmount $(list-m) first."; false; \
	     elif (/sbin/lsmod | grep -e ^$(list-m)' ') > /dev/null; then /sbin/rmmod $(list-m); \
	     	 if [ $$? != 0 ]; then echo "failed to unload $(list-m)"; false; \
	         else echo "unloaded $(list-m)"; fi \
	     fi \

clean:
	rm -f *.mod.c *.mod *.o *.ko .*.cmd .*.flags *.lst *~ .#*
	rm -f modules.order Module.symvers
	rm -rf .tmp_versions .$(obj-m:.o=)*

