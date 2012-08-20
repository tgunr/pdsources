#import <PMUtility/pm.h>
#import <Cocoa/Cocoa.h>

int main(int argc, const char *argv[]) {
	int killflag, ch;
	
    opterr = 0;
	killflag = 0;
	while ((ch = getopt(argc, (char * const*)argv, "kv")) != -1) {
		switch (ch) {
			case 'k':
				killflag = 1;
				break;
			case 'v':
				gDebugLevel++;
				break;
		}
	}
	argc -= optind;
	argv += optind;
	if (killflag) {
		system("rm $HOME/Library/Preferences/com.polymicrosystems.pickadisk.plist");
	}
    @autoreleasepool {
            NSApplicationMain(argc, argv);
    }
    return 0;
}
