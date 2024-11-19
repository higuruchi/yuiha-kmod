
// fs/ext3/namei.c
extern int yuiha_delete_version(handle_t *handle, 
		struct file *filp, unsigned long vno);
extern struct inode *yuiha_ilookup(struct super_block *sb, unsigned long ino);
extern int yuiha_detach_version(handle_t *handle, struct inode *inode);
extern int yuiha_vlink(struct file *filp, const char __user *newname);

// fs/ext3/inode.c
extern int cp_yuiha_stat(struct kstat *stat, struct timespec *vtime,
		struct yuiha_stat __user *ystat_buf);
extern void yuiha_getattr(struct file *filp, struct kstat *stat,
		struct timespec *vtime);
