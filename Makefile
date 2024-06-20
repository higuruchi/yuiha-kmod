SUBDIRS = fs

.PHONY: subdirs $(SUBDIRS) dbg  gdb

subdirs: $(SUBDIRS)

clean: RULE = clean
install: RULE = install
uninstall: RULE = uninstall
load: RULE = load

all clean install uninstall load: $(SUBDIRS)

$(SUBDIRS):
		$(MAKE) -C $@ $(RULE)

dbg:
	./debug/gen_gdb_script.sh

gdb:
	gdb --tui --cd=linux-2.6.32 vmlinux

