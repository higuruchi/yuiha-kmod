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

//extern int yuiha_create_snapshot(struct file *file);

