#include <linux/buffer_head.h>
#include <linux/page-flags.h>
#include <linux/fcntl.h>

// fs/ext3/namei.c
extern int yuiha_delete_version(handle_t *handle, 
		struct file *filp, unsigned long vno);
extern struct inode *yuiha_ilookup(struct super_block *sb, unsigned long ino);
extern int yuiha_detach_version(handle_t *handle, struct inode *inode);
extern int yuiha_vlink(struct file *filp, const char __user *newname);

// fs/ext3/yuiha_buffer_head.c
#define PRODUCER_BITS 31

enum {
	BH_Shared = BH_PrivateStart + 10,
};

BUFFER_FNS(Shared, shared)

enum {
	PG_shared = 0x20,
};

PAGEFLAG(Shared, shared)
TESTSCFLAG(Shared, shared)
__CLEARPAGEFLAG(Shared, shared)

int yuiha_block_write_begin(struct file *file, struct address_space *mapping,
				loff_t pos, unsigned len, unsigned flags,
				struct page **pagep, void **fsdata,
				get_block_t *get_block);

inline int test_producer_flg(__u32 datablock_number);
inline int set_producer_flg(__u32 datablock_number);
inline __u32 clear_producer_flg(__u32 datablock_number);

#define O_VERSION 020000000
#define O_PARENT 040000000
#define O_VSEARCH 0200000000
