#include <unistd.h>
#include <stdio.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>

int main(int argc, char *argv[])
{
	int fd;
	int ret = 0;

	if (argc < 2) {
		printf("invalid argument\n");
		goto err_out;
	}

	fd = open(argv[1], O_RDWR);
	if (fd < 0) {
		printf("file open error\n");
		goto err_out;
	}

	ret = fsync(fd);
	if (ret < 0) {
		printf("file sync error\n");
		goto err_out;
	}
	return 0;

err_out:
	return -1;
}
