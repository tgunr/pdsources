#import <Cocoa/Cocoa.h>

@interface StorageWindowController : NSWindowController {
    IBOutlet NSButton *carouselButton;
    IBOutlet NSButton *storeButton;
    IBOutlet NSButton *sourceButton;
    IBOutlet NSButton *batchModeButton;
    IBOutlet NSPathControl *sourcePath;
    IBOutlet NSPathControl *storePath;
	IBOutlet NSTextField *sourceExplainText;
	IBOutlet NSTextField *storeExplainText;
	
	id appDelegate;
	NSApplication *myApp;
}

- (IBAction)sourcePathClicked:(id)sender;
- (IBAction)storePathClicked:(id)sender;
- (IBAction)carouselButtonClicked:(id)sender;
- (IBAction)storeButtonClicked:(id)sender;
- (IBAction)sourceButtonClicked:(id)sender;
- (IBAction)batchModeButtonClicked:(id)sender;

- (void) setDelegate:(id)sender;
- (void)updateExplainText:(NSPathControl *)pathControl withTextField:(NSTextField *)textField withText:(NSString *)text;
@end
