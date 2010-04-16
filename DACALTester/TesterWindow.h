//
//  TesterWindow.h
//
//  Created by Dave Carlton on 01/03/10.
//  Copyright 2010 Polymicro Systems. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NSWindow : NSResponder {
    IBOutlet id delegate;
    IBOutlet NSView *initialFirstResponder;
    IBOutlet NSMenu *menu;
	IBOutlet NSTextField *slotNumber;
	IBOutlet NSPopUpButton *devicePopup;
	IBOutlet NSButton *resetButton;
	IBOutlet NSButton *gotoButton;
	IBOutlet NSButton *mountButton;
	IBOutlet NSButton *ejectButton;
}
- (IBAction)deminiaturize:(id)sender;
- (IBAction)makeKeyAndOrderFront:(id)sender;
- (IBAction)miniaturize:(id)sender;
- (IBAction)orderBack:(id)sender;
- (IBAction)orderFront:(id)sender;
- (IBAction)orderOut:(id)sender;
- (IBAction)performClose:(id)sender;
- (IBAction)performMiniaturize:(id)sender;
- (IBAction)performZoom:(id)sender;
- (IBAction)print:(id)sender;
- (IBAction)runToolbarCustomizationPalette:(id)sender;
- (IBAction)toggleToolbarShown:(id)sender;

- (IBAction)devicePopupChanged:(id)sender;
- (IBAction)resetClicked:(id)sender;
- (IBAction)gotoClicked:(id)sender;
- (IBAction)mountClicked:(id)sender;
- (IBAction)ejectClicked:(id)sender;

@end
// Local Variables:
// coding: utf-8-with-bom
// End:
