/*  linux/fs/ext3/namei.h
 *
 * Copyright (C) 2005 Simtec Electronics
 *	Ben Dooks <ben@simtec.co.uk>
 *
*/

extern struct dentry *ext3_get_parent(struct dentry *child);
extern struct dentry * yuiha_create_snapshot(
				struct dentry *parent,
				struct inode *new_version_target_i,
				struct dentry *lookup_dentry);
extern int yuiha_delete_version(handle_t *handle, 
		struct file *filp, unsigned long vno);
extern struct inode *yuiha_ilookup(struct super_block *sb, unsigned long ino);
extern int yuiha_detach_version(handle_t *handle, struct inode *inode);
extern int yuiha_vlink(struct file *filp, const char __user *newname);
