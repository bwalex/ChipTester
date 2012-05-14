#include <sys/mount.h>
#include <limits.h>
#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#include <string.h>

static
int
umount_match(const char *path_in)
{
	char linebuf[2048];
	char *path;
	char *p, *mnt_from, *mnt_on;
	FILE *fp;
	int rc = -1;

	if ((path = realpath(path_in, NULL)) == NULL)
		return -1;

	if ((fp = fopen("/proc/mounts", "r")) == NULL)
		goto out;

	do {
		p = fgets(linebuf, sizeof(linebuf), fp);
		if (p == NULL)
			if (feof(fp))
				break;
			else
				goto out;

		mnt_from = strsep(&p, " \t");
		mnt_on = strsep(&p, " \t");

		/* Check if it matches the passed-in string */
		if ((strcmp(path, mnt_from) != 0) &&
		    (strcmp(path, mnt_on) != 0))
			continue;

		rc = umount2(mnt_on, 0);
		if (rc)
			goto out;
	} while (1);


	rc = 0;
out:
	free(path);
	return rc;
}


int
main(int argc, char *argv[])
{
	int error;


	if (argc < 2) {
		fprintf(stderr, "Usage: umount2 <mount point>\n");
		exit(1);
	}

	error = umount_match(argv[1]);
	if (error)
		fprintf(stderr, "Error unmounting %s: %s\n",
		    argv[1], strerror(errno));

	return error;
}
