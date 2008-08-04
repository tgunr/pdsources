//
//  PADAddVolumeController.h
//  PickADisc
//
//  Created by Jack Small on 7/7/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "SimpleTreeNode.h"
#import "PADIndexProgressController.h"
#import "DACALTreeDataSource.h"
//#import <DiscID/DiscID.h>

@interface PADAddVolumeController : NSObject {

	IBOutlet	NSWindow		*sheetWindow;
	IBOutlet	NSButton		*okButton;
	IBOutlet	NSButton		*cancelButton;
	IBOutlet	NSImageView		*cdIcon;
	IBOutlet	NSPopUpButton	*carouselList;
	IBOutlet	NSPopUpButton	*slotTypeList;
	IBOutlet	NSComboBox		*slotTitle;
	IBOutlet	NSTextField		*slotNumber;
	IBOutlet	NSSlider		*slotDial;
	IBOutlet	NSSlider		*depthLevel;
	
	IBOutlet	NSWindow		*parentWindow;
	IBOutlet	PADIndexProgressController *progressController;
	
	DACALDeviceRef				currentDevice;
	NSMutableArray				*pendingVolumes;
//	BOOL						isPending;
//	NSString					*pendingTitle;
//	NSURL						*pendingURL;
}

-(IBAction) clickCancel:(id)sender;
-(IBAction) clickOK:(id)sender;
-(IBAction) clickType:(id)sender;
-(IBAction) clickChoose:(id)sender;
-(IBAction) slotChanged:(id)sender;
-(IBAction) slotTitleChanged:(id)sender;
-(IBAction) slotDialChanged:(id)sender;
-(IBAction) slotNameChanged:(id)sender;
-(IBAction) carouselChanged:(id)sender;

-(NSString*) pendingTitle;
//-(void)setPendingTitle:(NSString*)inTitle;
-(NSURL*) pendingURL;
//-(void)setPendingURL:(NSURL*)inPath;
-(NSInteger) pendingCount;

- (void)awakeFromNib;
 
- (void)deviceSelectionChanged:(NSArray *)newSet;
- (void)startSheet:(id)sender;
- (void)windowWillBeginSheet:(NSNotification *)notification;
- (void)syncMediaTitles;
- (void)detectedMounts:(NSArray *)newMounts;
- (void)ejectedMounts:(NSArray*)oldMounts;

-(void) indexProgressComplete:(PADIndexProgressController*)progress;
-(void) startIndexProgress:(NSTimer*)timer;

@end
