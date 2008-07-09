//
//  PADAddVolumeController.h
//  PickADisc
//
//  Created by Jack Small on 7/7/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "SimpleTreeNode.h"

@interface PADAddVolumeController : NSObject {

	IBOutlet	NSWindow		*sheetWindow;
	IBOutlet	NSButton		*okButton;
	IBOutlet	NSButton		*cancelButton;
	IBOutlet	NSImageView		*cdIcon;
	IBOutlet	NSPopUpButton	*carouselList;
	IBOutlet	NSPopUpButton	*slotTypeList;
	IBOutlet	NSTextField		*slotTitle;
	IBOutlet	NSTextField		*slotNumber;
	IBOutlet	NSSlider		*slotDial;
	IBOutlet	NSSlider		*depthLevel;
		
}

-(IBAction) clickCancel:(id)sender;
-(IBAction) clickOK:(id)sender;
-(IBAction) clickType:(id)sender;
-(IBAction) clickChoose:(id)sender;
-(IBAction) slotChanged:(id)sender;
-(IBAction) slotTitleChanged:(id)sender;
-(IBAction) slotDialChanged:(id)sender;
-(IBAction) carouselChanged:(id)sender;

- (void)awakeFromNib;
- (void)windowWillBeginSheet:(NSNotification *)notification;
 
@end
