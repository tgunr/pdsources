#import <Cocoa/Cocoa.h>

int main(int argc, const char *argv[]) {
	int killflag, ch;
	
	killflag = 0;
	while ((ch = getopt(argc, (char * const*)argv, "d")) != -1) {
		switch (ch) {
			case 'k':
				killflag = 1;
				break;
			case 'd':
				PMLOGSetVerbose(TRUE);
				break;
		}
	}
	argc -= optind;
	argv += optind;
	if (killflag) {
		system("rm $HOME/Library/Preferences/com.polymicrosystems.pickadisk.plist");
	}
    return NSApplicationMain(argc, argv);
}
