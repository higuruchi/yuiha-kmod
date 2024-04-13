#include <linux/buffer_head.h>

#define PRODUCER_BITS 31

enum {
	BH_Shared = BH_PrivateStart + 1,
};

BUFFER_FNS(Shared, shared)

int yuiha_block_write_begin(struct file *file, struct address_space *mapping,
				loff_t pos, unsigned len, unsigned flags,
				struct page **pagep, void **fsdata,
				get_block_t *get_block);

inline int test_producer_flg(__u32 datablock_number);
inline int set_producer_flg(__u32 datablock_number);
inline __u32 clear_producer_flg(__u32 datablock_number);

