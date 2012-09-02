#import <PMUtility/pmUtility.h>
#import <Cocoa/Cocoa.h>

int main(int argc, const char *argv[]) {
	int killflag, ch;
	
    opterr = 0;
	killflag = 0;
	while ((ch = getopt(argc, (char * const*)argv, "kd")) != -1) {
		switch (ch) {
			case 'k':
				killflag = 1;
				break;
			case 'd':
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
        @try {
            NSApplicationMain(argc, argv);
        }
        @catch (NSException *exception) {
            return -1;
        }
        return 0;
    }
}
