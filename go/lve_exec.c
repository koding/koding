#include <stdio.h>
#include <unistd.h>
#include <errno.h>
#include <lve/lve-ctl.h>

int main (int argc, char *argv[]) {
	if(argc <= 1) {
		return 64;
	}
	
	char* dir = getcwd(NULL, 0); // save current dir, it is lost when entering LVE
	
	struct liblve *lve = init_lve(malloc, free);
	if(lve == NULL) {
		printf("init_lve: %d\n", errno);
		return 71;
	}
	
	uint32_t lve_cookie;
	int result = lve_enter_flags(lve, getuid(), &lve_cookie, 0);
	if (result != 0) {
		printf("lve_enter_flags: %d\n", result);
		return 71;
	}
	
	result = lve_enter_fs(lve);
	if (result != 0) {
		printf("lve_enter_fs: %d\n", result);
		return 71;
	}
	
	chdir(dir);
	free(dir);
	return execvp(argv[1], &argv[1]);
}
