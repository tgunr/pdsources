#import <Cocoa/Cocoa.h>

@interface PADPrefsController : NSObject {
	
    IBOutlet id			tabView;
	IBOutlet NSToolbar	*tabToolbar;
	
}

- (IBAction)clickTool:(NSToolbarItem*)sender;

@end
