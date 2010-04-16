//
//  DACALTesterAppDelegate.h
//  DACALTester
//
//  Created by Dave Carlton on 01/03/10.
//  Copyright 2010 PolyMicro Systems. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class VolumeService;
@class AuthoringDeviceTester;
@class MediaDevice;
@class DeviceDataSource;
@class MediaStorage;

@interface DACALTesterAppDelegate : NSObject <NSApplicationDelegate> {
	NSWindow               * window;
	IBOutlet NSTextField   * dacalSlotNumber;
	IBOutlet NSTextField   * dacalDriveSlotNumber;
	IBOutlet NSTextField   * dacalDriveSlotNumberLabel;
	IBOutlet NSPopUpButton * dacalDevicePopup;
	IBOutlet NSButton      * dacalResetButton;
	IBOutlet NSButton      * dacalGotoButton;
	IBOutlet NSButton      * dacalMountButton;
	IBOutlet NSButton      * dacalEjectButton;
	IBOutlet NSButton      * dacalCloseButton;
	
	IBOutlet NSPopUpButton * drivePopup;
	IBOutlet NSButton      * driveMountButton;
	IBOutlet NSButton      * driveUnountButton;
	IBOutlet NSButton      * driveEjectButton;
	
	IBOutlet NSPopUpButton * volumePopup;
	IBOutlet NSButton      * volumeUnmountButton;
	
	AuthoringDeviceTester * authoringDeviceTester;
	MediaDevice			  * mediaDevice;
	//	DeviceDataSource      * driveSource;
	VolumeService		  * volumeService;
	MediaStorage		  * mediaStorage;
}

-(IBAction) dacalDevicePopupChanged: (id) sender;
-(IBAction) dacalResetClicked: (id) sender;
-(IBAction) dacalGotoClicked: (id) sender;
-(IBAction) dacalMountClicked: (id) sender;
-(IBAction) dacalEjectClicked: (id) sender;
-(IBAction) dacalCloseDoor: (id) sender;

-(IBAction) drivePopupChanged: (id) sender;
-(IBAction) driveMountClicked: (id) sender;
-(IBAction) driveUnmountClicked: (id) sender;
-(IBAction) driveEjectClicked: (id) sender;

-(IBAction) volumePopupChanged: (id) sender;
-(IBAction) volumeUnmountClicked: (id) sender;

-(IBAction) slotTextDidChange:(id) sender;

-(void) appendLogText: (NSString *) logString;

@property (assign) IBOutlet NSWindow      * window;
@property (assign) IBOutlet NSTextField   * dacalSlotNumber;
@property (assign) IBOutlet NSTextField   * dacalDriveSlotNumber;
@property (assign) IBOutlet NSPopUpButton * dacalDevicePopup;
@property (assign) IBOutlet NSPopUpButton * drivePopup;
@property (assign) IBOutlet NSPopUpButton * volumePopup;
@property (assign) AuthoringDeviceTester  * authoringDeviceTester;
@property (assign) MediaDevice            * mediaDevice;
@property (assign) DeviceDataSource       * driveSource;
@property (assign) VolumeService		  * volumeService;
@property (assign) MediaStorage  		  * mediaStorage;

@end

// Local Variables:
// coding: utf-8-with-bom
// End:
