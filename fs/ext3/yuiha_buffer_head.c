#include <linux/kernel.h>
#include <linux/syscalls.h>
#include <linux/fs.h>
#include <linux/mm.h>
#include <linux/percpu.h>
#include <linux/slab.h>
#include <linux/capability.h>
#include <linux/blkdev.h>
#include <linux/file.h>
#include <linux/quotaops.h>
#include <linux/highmem.h>
#include <linux/module.h>
#include <linux/writeback.h>
#include <linux/hash.h>
#include <linux/suspend.h>
#include <linux/buffer_head.h>
#include <linux/task_io_accounting_ops.h>
#include <linux/bio.h>
#include <linux/notifier.h>
#include <linux/cpu.h>
#include <linux/bitops.h>
#include <linux/mpage.h>
#include <linux/bit_spinlock.h>
#include "yuiha_buffer_head.h"

static int __yuiha_block_prepare_write(struct inode *inode, struct page *page,
		unsigned from, unsigned to, get_block_t *get_block)
{
	unsigned block_start, block_end;
	sector_t block;
	int err = 0;
	unsigned blocksize, bbits;
	struct buffer_head *bh, *head, *wait[2], **wait_bh=wait;

	BUG_ON(!PageLocked(page));
	BUG_ON(from > PAGE_CACHE_SIZE);
	BUG_ON(to > PAGE_CACHE_SIZE);
	BUG_ON(from > to);

	blocksize = 1 << inode->i_blkbits;
	if (!page_has_buffers(page))
		create_empty_buffers(page, blocksize, 0);
	head = page_buffers(page);

	bbits = inode->i_blkbits;
	block = (sector_t)page->index << (PAGE_CACHE_SHIFT - bbits);

	for(bh = head, block_start = 0; bh != head || !block_start;
	    block++, block_start=block_end, bh = bh->b_this_page) {
		block_end = block_start + blocksize;
		if (block_end <= from || block_start >= to) {
			if (PageUptodate(page)) {
				if (!buffer_uptodate(bh))
					set_buffer_uptodate(bh);
			}
			continue;
		}
		if (buffer_new(bh))
			clear_buffer_new(bh);
		if (!buffer_mapped(bh) || buffer_shared(bh)) {
			WARN_ON(bh->b_size != blocksize);
			err = get_block(inode, block, bh, 1);
			if (err)
				break;
			if (buffer_new(bh)) {
				unmap_underlying_metadata(bh->b_bdev,
							bh->b_blocknr);
				if (PageUptodate(page)) {
					clear_buffer_new(bh);
					set_buffer_uptodate(bh);
					mark_buffer_dirty(bh);
					continue;
				}
				if (block_end > to || block_start < from)
					zero_user_segments(page,
						to, block_end,
						block_start, from);
				continue;
			}

			if (buffer_shared(bh))
				clear_buffer_shared(bh);
		}
		if (PageUptodate(page)) {
			if (!buffer_uptodate(bh))
				set_buffer_uptodate(bh);
			continue; 
		}
		if (!buffer_uptodate(bh) && !buffer_delay(bh) &&
		    !buffer_unwritten(bh) &&
		     (block_start < from || block_end > to)) {
			ll_rw_block(READ, 1, &bh);
			*wait_bh++=bh;
		}
	}
	/*
	 * If we issued read requests - let them complete.
	 */
	while(wait_bh > wait) {
		wait_on_buffer(*--wait_bh);
		if (!buffer_uptodate(*wait_bh))
			err = -EIO;
	}
	if (unlikely(err))
		page_zero_new_buffers(page, from, to);
	return err;
}

/*
 * block_write_begin takes care of the basic task of block allocation and
 * bringing partial write blocks uptodate first.
 *
 * If *pagep is not NULL, then block_write_begin uses the locked page
 * at *pagep rather than allocating its own. In this case, the page will
 * not be unlocked or deallocated on failure.
 */
int yuiha_block_write_begin(struct file *file, struct address_space *mapping,
			loff_t pos, unsigned len, unsigned flags,
			struct page **pagep, void **fsdata,
			get_block_t *get_block)
{
	struct inode *inode = mapping->host;
	int status = 0;
	struct page *page;
	pgoff_t index;
	unsigned start, end;
	int ownpage = 0;

	index = pos >> PAGE_CACHE_SHIFT;
	start = pos & (PAGE_CACHE_SIZE - 1);
	end = start + len;

	page = *pagep;
	if (page == NULL) {
		ownpage = 1;
		page = grab_cache_page_write_begin(mapping, index, flags);
		if (!page) {
			status = -ENOMEM;
			goto out;
		}
		*pagep = page;
	} else
		BUG_ON(!PageLocked(page));

	status = __yuiha_block_prepare_write(inode, page, start, end, get_block);
	if (unlikely(status)) {
		ClearPageUptodate(page);

		if (ownpage) {
			unlock_page(page);
			page_cache_release(page);
			*pagep = NULL;

			/*
			 * prepare_write() may have instantiated a few blocks
			 * outside i_size.  Trim these off again. Don't need
			 * i_size_read because we hold i_mutex.
			 */
			if (pos + len > inode->i_size)
				vmtruncate(inode, inode->i_size);
		}
	}

out:
	return status;
}

inline int test_producer_flg(__u32 datablock_number) {
	if (datablock_number & 1 << PRODUCER_BITS)
		return 1;
	return 0;
}

inline int set_producer_flg(__u32 datablock_number) {
	return datablock_number | 1 << PRODUCER_BITS;
}

inline __u32 clear_producer_flg(__u32 datablock_number) {
	return datablock_number & ~(1 << PRODUCER_BITS);
}
