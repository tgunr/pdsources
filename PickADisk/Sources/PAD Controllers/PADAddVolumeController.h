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
#import "DACALDeviceObjC.h"
#import "DACVolume.h"
#import "PADFlavorImageView.h"

@interface PADAddVolumeController : NSObject {

	IBOutlet	NSWindow*				sheetWindow;
	IBOutlet	NSButton*				okButton;
	IBOutlet	NSButton*				cancelButton;
//	IBOutlet	NSImageView*			cdIcon;
	IBOutlet	NSPopUpButton*			carouselList;
	IBOutlet	NSPopUpButton*			slotTypeList;
	IBOutlet	NSComboBox*				slotTitle;
	IBOutlet	NSTextField*			slotNumber;
	IBOutlet	NSSlider*				slotDial;
	IBOutlet	NSSlider*				depthLevel;
	IBOutlet	NSButton*				ejectButton;
	
	IBOutlet	NSWindow*				parentWindow;
 IBOutlet PADIndexProgressController*	progressController;
	
	IBOutlet	PADFlavorImageView*		flavorIcon;
	IBOutlet	PADVolumeIconView*		volumeIcon;
	IBOutlet	NSPopUpButton*			volumeList;
	IBOutlet	NSTextField*			alternateTitle;
	IBOutlet	NSButton*				clearTitleButton;
	IBOutlet	NSButton*				gotoSlotButton;
	
	IBOutlet	NSProgressIndicator*	indexProgressBar;
	IBOutlet	NSTextField*			indexProgressPrompt;
	
	DACALDeviceRef						currentDevice;
	NSMutableArray*						pendingVolumes;
	DACALSlot*							pendingSlot;

	NSString*							customTitle;
	NSString*							customFlavor;
	
	NSTask*								indexProgressTask;
	
//	BOOL						isPending;
//	NSString					*pendingTitle;
//	NSURL						*pendingURL;
}

-(IBAction) clickCancel:(id)sender;
-(IBAction) clickOK:(id)sender;
-(IBAction) clickType:(id)sender;
-(IBAction) clickChoose:(id)sender;
-(IBAction) clickEject:(id)sender;
-(IBAction) slotChanged:(id)sender;
-(IBAction) slotTitleChanged:(id)sender;
-(IBAction) slotDialChanged:(id)sender;
-(IBAction) slotNameChanged:(id)sender;
-(IBAction) carouselChanged:(id)sender;
-(IBAction) clickGotoSlot:(id)sender;
-(IBAction) clickClearTitle:(id)sender;

-(NSString*)customTitle;
-(void)setCustomTitle:(NSString*)newTitle;

-(NSString*)customFlavor;
-(void)setCustomFlavor:(NSString*)newFlavor;

-(DACVolume*)pendingVolume;

-(DACALSlot*)currentSlot;
-(DACALDeviceRef)currentDeviceRef;

-(DACALSlot*)updatePendingSlot;
-(DACALSlot*)pendingSlot;
-(void)setPendingSlot:(DACALSlot*)newSlot;

-(NSString*) pendingTitle;
//-(void)setPendingTitle:(NSString*)inTitle;
-(NSURL*) pendingURL;
//-(void)setPendingURL:(NSURL*)inPath;
-(NSInteger) pendingCount;

- (void)awakeFromNib;
 
- (void)changeToFlavor:(NSString*)slotType;
- (void)setPrompt:(NSString*)promptString;
- (void)activeItemState:(BOOL)dataItemEnabled;

- (void)deviceSelectionChanged:(NSArray *)newSet;
- (void)startSheet:(id)sender;
- (void)windowWillBeginSheet:(NSNotification *)notification;
- (void)syncMediaTitles;

- (void)detectedVolumes:(NSArray *)newVolumes;
- (void)ejectedVolumes:(NSArray*)oldVolumes;
//- (void)detectedMounts:(NSArray *)newMounts;
//- (void)ejectedMounts:(NSArray*)oldMounts;

-(void) indexProgressComplete:(PADIndexProgressController*)progress;
-(void) startIndexProgress:(NSTimer*)timer;
-(void)indexDeviceControlFinished:(id)sender;

@end
