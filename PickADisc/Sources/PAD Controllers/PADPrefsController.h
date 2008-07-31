#import <Cocoa/Cocoa.h>

@interface PADPrefsController : NSObject {
	
    IBOutlet id			tabView;
	IBOutlet NSToolbar	*tabToolbar;
	IBOutlet NSTextField *updateText;
	
}

- (IBAction)clickTool:(NSToolbarItem*)sender;
- (IBAction)checkForUpdatesAndRefreshDate:(id)sender;
- (IBAction)refreshUpdateDate:(id)sender;
- (IBAction)provideFeedback:(id)sender;

@end
