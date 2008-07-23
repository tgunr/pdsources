// MainWindowController.h

#import <Cocoa/Cocoa.h>
#import "PMTB_AppDelegate.h"

@class PMTB_AppDelegate;

@interface MainWindowController : NSWindowController {
    IBOutlet NSButton *processButton;
    IBOutlet NSButton *storeButton;
    IBOutlet NSButton *sourceButton;
    IBOutlet NSButton *batchModeButton;
    IBOutlet NSPathControl *sourcePath;
    IBOutlet NSPathControl *storePath;
	IBOutlet NSTextField *sourceExplainText;
	IBOutlet NSTextField *storeExplainText;
	
	NSApplication *myApp;
	PMTB_AppDelegate *appDelegate;
}

- (IBAction)sourcePathClicked:(id)sender;
- (IBAction)storePathClicked:(id)sender;
- (IBAction)processButtonClicked:(id)sender;
- (IBAction)storeButtonClicked:(id)sender;
- (IBAction)sourceButtonClicked:(id)sender;
- (IBAction)batchModeButtonClicked:(id)sender;

- (void) setDelegate:(PMTB_AppDelegate *)sender;
-(void)updateExplainText:(NSPathControl *)pathControl withTextField:(NSTextField *)textField withText:(NSString *)text;
@end
