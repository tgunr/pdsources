#import <Cocoa/Cocoa.h>

int main(int argc, const char *argv[]) {
	int dflag, ch;
	
	dflag = 0;
	while ((ch = getopt(argc, (char * const*)argv, "d")) != -1) {
		switch (ch) {
			case 'd':
				dflag = 1;
				break;
		}
	}
	argc -= optind;
	argv += optind;
	if (dflag) {
		system("rm $HOME/Library/Preferences/com.polymicrosystems.pickadisk.plist");
	}
    return NSApplicationMain(argc, argv);
}
