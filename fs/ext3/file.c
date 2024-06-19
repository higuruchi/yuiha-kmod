/*
 *  linux/fs/ext3/file.c
 *
 * Copyright (C) 1992, 1993, 1994, 1995
 * Remy Card (card@masi.ibp.fr)
 * Laboratoire MASI - Institut Blaise Pascal
 * Universite Pierre et Marie Curie (Paris VI)
 *
 *  from
 *
 *  linux/fs/minix/file.c
 *
 *  Copyright (C) 1991, 1992  Linus Torvalds
 *
 *  ext3 fs regular file handling primitives
 *
 *  64-bit file support on 64-bit platforms by Jakub Jelinek
 *	(jj@sunsite.ms.mff.cuni.cz)
 */

#include <linux/time.h>
#include <linux/fs.h>
#include <linux/jbd.h>
#include <linux/ext3_fs.h>
#include <linux/ext3_jbd.h>
#include "xattr.h"
#include "acl.h"
#include "namei.h"
#include "yuiha_flags.h"

/*
 * Called when an inode is released. Note that this is different
 * from ext3_file_open: open gets called at every open, but release
 * gets called only when /all/ the files are closed.
 */
static int ext3_release_file (struct inode * inode, struct file * filp)
{
	struct yuiha_inode_info *yi;
	struct dentry *dentry = filp->f_dentry,
								//*parent_version = filp->f_dentry->d_fsdata,
								*parent = filp->f_dentry->d_parent;
	struct qstr dname;
	unsigned long hash;
	printk("ext3_release_file 44 %lu %lu\n", inode->i_ino, inode->i_count);

	if (EXT3_I(inode)->i_state & EXT3_STATE_FLUSH_ON_CLOSE) {
		filemap_flush(inode->i_mapping);
		EXT3_I(inode)->i_state &= ~EXT3_STATE_FLUSH_ON_CLOSE;
	}
	/* if we are the last writer on the inode, drop the block reservation */
	if ((filp->f_mode & FMODE_WRITE) &&
			(atomic_read(&inode->i_writecount) == 1))
	{
		mutex_lock(&EXT3_I(inode)->truncate_mutex);
		ext3_discard_reservation(inode);
		mutex_unlock(&EXT3_I(inode)->truncate_mutex);
	}
	if (is_dx(inode) && filp->private_data)
		ext3_htree_free_dir_info(filp->private_data);

	// only yuihafs
	yi = YUIHA_I(inode);
	if (yi->parent_inode) {
		printk("ext3_release_file 63 %lu %lu\n", inode->i_ino, inode->i_count);
		//iput(yi->parent_inode);
		//yi->parent_inode = NULL;
	}

	return 0;
}

static int yuiha_parent_file_open(struct file *filp)
{
	struct inode *opened_inode = filp->f_dentry,
							 *parent_inode = NULL;
	struct yuiha_inode_info *opened_yi = YUIHA_I(opened_inode),
													*parent_yi = NULL;
	struct super_block *sb = opened_inode->i_sb;

	// Parent version not found
	if (!opened_yi->i_parent_ino)
		return 0;

	if (!opened_yi->parent_inode) {
		parent_inode = ext3_iget(sb, opened_yi->i_parent_ino);
		opened_yi->parent_inode = parent_inode;
	}

	return 0;
}

static int yuiha_file_open(struct inode * inode, struct file *filp)
{
	printk("yuiha_file_open ino=%lu %lu\n", inode->i_ino, inode->i_count);
	int ret = generic_file_open(inode, filp);
	// if (ret)
	// 	return ret;

	// if (filp->f_flags & (O_PARENT | O_RDONLY)) {
	// 	printk("parent version open!!\n");
	// } else if (filp->f_flags & O_VERSION) {
	// 	printk("versioned!!\n");
	// 	yuiha_create_snapshot(filp);
	// }

	return ret;
}

const struct file_operations ext3_file_operations = {
	.llseek		= generic_file_llseek,
	.read		= do_sync_read,
	.write		= do_sync_write,
	.aio_read	= generic_file_aio_read,
	.aio_write	= generic_file_aio_write,
	.unlocked_ioctl	= ext3_ioctl,
#ifdef CONFIG_COMPAT
	.compat_ioctl	= ext3_compat_ioctl,
#endif
	.mmap		= generic_file_mmap,
	.open		= generic_file_open,
	.release	= ext3_release_file,
	.fsync		= ext3_sync_file,
	.splice_read	= generic_file_splice_read,
	.splice_write	= generic_file_splice_write,
};

const struct file_operations yuiha_file_operations = {
	.llseek		= generic_file_llseek,
	.read		= do_sync_read,
	.write		= do_sync_write,
	.aio_read	= generic_file_aio_read,
	.aio_write	= generic_file_aio_write,
	.unlocked_ioctl	= ext3_ioctl,
#ifdef CONFIG_COMPAT
	.compat_ioctl	= ext3_compat_ioctl,
#endif
	.mmap		= generic_file_mmap,
	.open		= yuiha_file_open,
	.release	= ext3_release_file,
	.fsync		= ext3_sync_file,
	.splice_read	= generic_file_splice_read,
	.splice_write	= generic_file_splice_write,
};

const struct inode_operations ext3_file_inode_operations = {
	.truncate	= ext3_truncate,
	.setattr	= ext3_setattr,
#ifdef CONFIG_EXT3_FS_XATTR
	.setxattr	= generic_setxattr,
	.getxattr	= generic_getxattr,
	.listxattr	= ext3_listxattr,
	.removexattr	= generic_removexattr,
#endif
	.check_acl	= ext3_check_acl,
	.fiemap		= ext3_fiemap,
};

