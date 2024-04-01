#include <stdio.h>
#include <stdlib.h>
#include <fcntl.h>
#include <string.h>
#include <unistd.h>
#include <sys/time.h>
#include <sys/resource.h>

#define SECTOR_SIZE 512
#define MAXWSIZE 1000000000
char wbuf[MAXWSIZE];

#define tval2dbl(tv) (double)(tv.tv_sec+tv.tv_usec/1000000.0)

typedef struct {
  double cpu_usr;
  double cpu_sys;
  double cur_time;
} TM_STRUC;

#define tval2dbl(tv) (double)(tv.tv_sec+tv.tv_usec/1000000.0)

TM_STRUC get_tm()
{
  TM_STRUC tms;
  struct rusage cusage;
  struct timeval ctime;

  getrusage(RUSAGE_SELF, &cusage);
  gettimeofday(&ctime, NULL);
  tms.cpu_usr  = tval2dbl(cusage.ru_utime);
  tms.cpu_sys  = tval2dbl(cusage.ru_stime);
  tms.cur_time = tval2dbl(ctime);
  return tms;
}

// Write data to specified location and size
void writedata(int fd, char *data, off_t location, size_t size)
{
  size_t wsize;

  if (lseek(fd, location, SEEK_SET) < 0) {
    perror("lseek");
    exit(1);
  }
  do {
    wsize = write(fd, data, size);
    if (wsize < 0) {
      perror("write");
      exit(1);
    }
    size -= wsize;
  } while (size > 0);
}

void Usage(char *cmd)
{
  fprintf(stderr, "Usage: %s target_file < \n", cmd);
  exit(1);
}

int getparam(off_t *offset, size_t *wsize)
{
  char linebuf[256];
  char dummy_c;
  int dummy_i;

  if (fgets(linebuf, 256, stdin) == NULL) return 0; // EOF
  sscanf(linebuf, "%c,%ld,%d,%ld", &dummy_c, offset, &dummy_i, wsize);
  return 1;
}

int get_appendparam(char *param, size_t *append_size)
{
  char *p = strtok(param, "=");
  if (!strncmp(p, "append", strlen("append"))) {
    p = strtok(NULL, "=");
    *append_size = (size_t) atoi(p);
  }

  return 0;
}

int main(int argc, char *argv[])
{
  int fd;
  off_t seek_pos;
  size_t wsize, append_size;
  long totalsize;
  int loop;
  TM_STRUC start, finish;

  if (argc > 3) Usage(argv[0]);

  if (argc == 3) {
      if (get_appendparam(argv[2], &append_size)) {
	  	perror(argv[2]);
		exit(1);
	  }
	  fd = open(argv[1], O_WRONLY | O_CREAT | O_APPEND ,0644);
  } else if (argc == 2) {
	  fd = open(argv[1], O_WRONLY | O_CREAT ,0644);
  } else {
  	Usage(argv[0]);
	exit(1);
  }
  
  if (fd < 0) {
    perror(argv[1]);
    exit(1);
  }

  memset(wbuf, 0x55, MAXWSIZE);
  totalsize = 0;
  loop = 0;
  start = get_tm();
  if (argc == 3) {
    write(fd, wbuf, append_size);
    totalsize += append_size;
  } else {
    while (getparam(&seek_pos, &wsize)) {
      if ((seek_pos < 0) || (wsize < 0) || wsize > MAXWSIZE) {
        fprintf(stderr, "Invalid parameter %ld, %ld\n", seek_pos, wsize);
        exit(1);
      }
      writedata(fd, wbuf, seek_pos*SECTOR_SIZE, wsize);
      totalsize += wsize;
    }
  }
  close(fd);
  finish = get_tm();
  printf("%lf bytes/sec (= %ld, %lf)\n\n",
         totalsize/(finish.cur_time - start.cur_time),
         totalsize, finish.cur_time - start.cur_time);
 
  return 0;
}
