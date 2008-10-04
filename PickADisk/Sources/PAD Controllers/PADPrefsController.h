#import <Cocoa/Cocoa.h>

@interface PADPrefsController : NSObject {
	
	IBOutlet NSWindow*			prefsWindow;
    IBOutlet id					tabView;
	IBOutlet NSToolbar*			tabToolbar;

	IBOutlet NSTextField*		updateText;
	
	IBOutlet NSButton*			installDriver;
	IBOutlet NSButton*			removeDriver;
	IBOutlet NSImageView*		driverNotImage;
	IBOutlet NSTextField*		driverPrompt;
	
}

- (IBAction)runPreferences:(id)sender;
- (IBAction)clickTool:(NSToolbarItem*)sender;
//- (IBAction)checkForUpdatesAndRefreshDate:(id)sender;
- (IBAction)refreshUpdateDate:(id)sender;
- (IBAction)provideFeedback:(id)sender;

- (IBAction)runDriverInstaller:(id)sender;

- (void)updateDriverPane;

@end
