//
//  DACALTesterAppDelegate.m
//  DACALTester
//
//  Created by Dave Carlton on 01/03/10.
//  Copyright 2010 PolyMicro Systems. All rights reserved.
//

#import "DACALTesterAppDelegate.h"
#import "IconFamily.h"
#import "dacallib.h"
#import "dacalconstants.h"
#import "pmsCFUtility.h"
#import "pmsDACALUtility.h"
#import <DiskArbitration/DiskArbitration.h>
#import <IOKit/scsi/SCSICommandOperationCodes.h>
#import <IOKit/scsi/SCSITask.h>
#import <IOKit/scsi/SCSITaskLib.h>
#import <IOKit/storage/IOMedia.h>
#import "Volume.h";
#import "VolumeService.h";
#import "DeviceDataSource.h"
#import "MediaDevice.h"
#import "AuthoringDeviceTester.h"
#import "MediaStorage.h"

@implementation DACALTesterAppDelegate

@synthesize window;
@synthesize dacalSlotNumber;
@synthesize dacalDriveSlotNumber;
@synthesize dacalDevicePopup;
@synthesize drivePopup;
@synthesize volumePopup;
@synthesize authoringDeviceTester;
@synthesize mediaDevice;
@synthesize driveSource;
@synthesize volumeService;
@synthesize mediaStorage;

enum {
	kUnmountFailed    = -2,
	kUnmountCancelled = -1,
	kStatusOK         = 0
};

-(void) appendLogText: (NSString *) logString
{
	PMLOG(1, logString);
}

// Drive methods
-(MediaDevice *) selectedDevice
{
	NSString * popupTitle = [drivePopup titleOfSelectedItem];
	MediaDevice * theDevice = [driveSource deviceProductNameIs: popupTitle];
	return theDevice;
}

-(DACALDeviceRef) dacalGetDeviceRef
{
	NSInteger      boxIndex      = [dacalDevicePopup indexOfSelectedItem];
	DACALDeviceRef deviceId = DACALDevicesCopyDeviceRefForIndex(boxIndex, NULL);
	
	return deviceId;
}

-(DACALSlotNum) getSlotNumber
{
	NSInteger slot = [dacalSlotNumber intValue];

	return (DACALSlotNum)slot;
}

- (void) awakeFromNib
{
	// Setup notifications for text changes
//	[dacalDriveSlotNumber setDelegate:self];
	[[NSNotificationCenter defaultCenter] addObserver:self selector: @selector(dacalSlotNumberEntered) name:NSControlTextDidChangeNotification object:nil];
	
}

-(void) applicationDidFinishLaunching: (NSNotification *) aNotification
{
	volumeService = [[VolumeService alloc] init];
	[volumeService initializeService];
	
	// Initialize the volumes popup
	[volumePopup removeAllItems];
	NSInteger   volumeCount = [[volumeService knownVolumes] count];
	if (volumeCount) {
		NSMutableArray *volumes = [volumeService knownVolumes];
		for(int i = 0; i < volumeCount; i++) {
			Volume * aVolume = [volumes objectAtIndex:i];
			[volumePopup addItemWithTitle: [aVolume mediaTitle]];
		}
	}
	
	[self setMediaStorage: [[MediaStorage alloc] init]];
						   
	// Initialize the drives popup
//	driveSource = [[DeviceDataSource alloc] init];
	[drivePopup removeAllItems];
	NSInteger driveCount = [[mediaStorage theDeviceList] count];
	if (driveCount) {
		NSMutableArray *drives = [mediaStorage theDeviceList];
		for (int i =0; i < driveCount; i++) {
			MediaDevice *drive = [drives objectAtIndex:i];
			[drivePopup addItemWithTitle: [drive productName]];
		}
	}

	// Initialize the carousels pop
	DACALDevicesInitialize(&DACALDevicesAdded);
	if (gDACALBoxes.boxCount != 0) {
		[dacalDevicePopup removeAllItems];
		for (int i = 0; i < gDACALBoxes.boxCount; i++) {
			DACALDeviceRef boxRef = DACALDevicesCopyDeviceRefForIndex(i, NULL);
			CFStringRef    boxModel  = DACALCommandCopyModel(boxRef, NULL);
			[dacalDevicePopup addItemWithTitle: (NSString *)boxModel];
		}
	}
	[self dacalDevicePopupChanged:self];
	
} // applicationDidFinishLaunching


// dissent_mount.c

static DAApprovalSessionRef gSession;

DADissenterRef
mountApprovalCallback(DADiskRef disk, void * context)
{
	DADissenterRef dissenter = DADissenterCreate( kCFAllocatorDefault,
		kDAReturnNotPermitted,
		CFSTR("mount disallowed") );

	PMLOG( 1, @"%s: mount disallowed\n", DADiskGetBSDName(disk) );
	return dissenter;
}

DADissenterRef
ejectApprovalCallback(DADiskRef disk, void * context)
{
//	DADissenterRef dissenter = DADissenterCreate( kCFAllocatorDefault,
//		kDAReturnNotPermitted,
//		CFSTR("eject allowed") );

	PMLOG( 1, @"%s: eject allowed\n", DADiskGetBSDName(disk) );
	return 0;
}

void
allowMount(void)
{
	DAApprovalSessionUnscheduleFromRunLoop(gSession, CFRunLoopGetCurrent(),
		kCFRunLoopDefaultMode);

	DAUnregisterApprovalCallback(gSession, mountApprovalCallback, NULL);

	if (gSession)
		CFRelease(gSession);
}

void
preventMount(void)
{
	gSession = DAApprovalSessionCreate(kCFAllocatorDefault);
	if (!gSession) {
		PMLOG(1, @"failed to create Disk Arbitration session");
		return;
	} else {
		PMLOG(1, @"preventing mount");
	}

//    DARegisterDiskMountApprovalCallback(gSession, NULL, mountApprovalCallback, NULL);
	DARegisterDiskEjectApprovalCallback(gSession, NULL, ejectApprovalCallback, NULL);

	DAApprovalSessionScheduleWithRunLoop(gSession, CFRunLoopGetCurrent(),
		kCFRunLoopDefaultMode);

//    CFRunLoopRunInMode(kCFRunLoopDefaultMode, 120 /* seconds */, false);
} // preventMount

-(Boolean) isExclusiveAccessAvailable
{
	MMCDeviceInterface      ** theInterface = NULL;
	SCSITaskDeviceInterface ** devInterface = NULL;
	Boolean                    status                              = false;

	theInterface = [[self authoringDeviceTester] interface];
	require( (theInterface != NULL), ErrorExit );

	devInterface = (*theInterface)->GetSCSITaskDeviceInterface(theInterface);
	require( (devInterface != NULL), ErrorExit );

	// Ok. We have the SCSITaskDeviceInterface, let's see if
	// exclusive access is available.
	status = (*devInterface)->IsExclusiveAccessAvailable(devInterface);
	if (status == true) {
		PMLOG(1, @"Exclusive Access Is Available.\n");
	} else {
		PMLOG(1, @"Exclusive Access Is Not Available.\n");
	}

	(*devInterface)->Release(devInterface);

ErrorExit:

	return status;
} // isExclusiveAccessAvailable

-(void) getExclusiveAccess
{
	MMCDeviceInterface ** theInterface = NULL;
	int                   result                          = 0;

	// Try to unmount the media if there is any.
//	result = [ self unmountMedia ];

	// If the dialog was cancelled just return.
//	if ( result == kUnmountCancelled )
//	{
//		return;
//	}
//
//	else if ( result == kUnmountFailed )
//	{
//		PMLOG(1, @"*********** ERROR Unable to unmount media ***********\n");
//	}

	theInterface = [[self authoringDeviceTester] interface];

	// Else, we can proceed because no media was present. This allows us to just do our test.
	if (theInterface != NULL) {
		SCSITaskDeviceInterface ** devInterface = NULL;
		devInterface = (*theInterface)->GetSCSITaskDeviceInterface(theInterface);
		if (devInterface != NULL) {
			// Ok. We have the SCSITaskDeviceInterface, let's use it to get exclusive access
			// and run our test suite.
//			[ self runExclusiveTestSuite: devInterface ];

			(*devInterface)->Release(devInterface);
		}
	}
} // getExclusiveAccess

-(void) existingMediaRemoved: (NSString *) oldMediaPath
{
	PMLOG(2, @"Removed Volume");

	Boolean status = [self isExclusiveAccessAvailable];
	if (status) {
		[self getExclusiveAccess];
	}
	preventMount();

	DACALDeviceRef deviceRef = [self dacalGetDeviceRef];
	if (deviceRef) {
		// This should probably be moved into a DACALDevice method
		// If this slot beloags to a Powerdrive we need to send a eject command while the volume is unmounted
//		if ( DACALIsDC016(deviceRef) )
//			DACALCommandDVDEject(deviceRef);
	}
} // existingMediaRemoved

-(void) existingMediaRemovedNotification: (id) aNotification
{
	[self existingMediaRemoved: [NSString stringWithString: [[aNotification userInfo] valueForKey:
	                                                         @"NSDevicePath"]]];
}

-(IBAction) dacalDevicePopupChanged: (id) sender
{
	NSString *model = [dacalDevicePopup titleOfSelectedItem];
	NSComparisonResult result = [model compare: (NSString *)DACALDC016CFName];
	if (result == 0) {
		[dacalDriveSlotNumber setHidden:NO];
		[dacalDriveSlotNumberLabel setHidden:NO];
		DACALResult outError = 0;
		DACALDeviceRef deviceID = [self dacalGetDeviceRef];
		DACALSlotNum slot = DACALCommandDVDGetSlot(deviceID, &outError);
		[dacalDriveSlotNumber setIntegerValue: slot];
	} else {
		[dacalDriveSlotNumber setHidden:YES];
		[dacalDriveSlotNumberLabel setHidden:YES];
	}	

}

-(IBAction) dacalResetClicked: (id) sender
{
	DACALCommandReset([self dacalGetDeviceRef]);
}

-(IBAction) dacalGotoClicked: (id) sender
{
	DACALSlotNum slot = [self getSlotNumber];
	DACALResult  result;
	
	result = DACALCommandCloseDoor([self dacalGetDeviceRef]);
	while ( DACALGetStatus([self dacalGetDeviceRef]) ) {
		sleep(1);
	}
	if (slot)
		result = DACALCommandMoveToSlot([self dacalGetDeviceRef], slot);
}

-(IBAction) dacalMountClicked: (id) sender
{
	DACALSlotNum slot = [self getSlotNumber];
	DACALResult  result;
	
	result = DACALCommandCloseDoor([self dacalGetDeviceRef]);
	while ( DACALGetStatus([self dacalGetDeviceRef]) ) {
		sleep(1);
	}
	if (slot)
		result = DACALCommandDVDMoveTo([self dacalGetDeviceRef], slot);
}

-(IBAction) dacalEjectClicked: (id) sender
{
	DACALCommandDVDEject([self dacalGetDeviceRef]);
}

-(IBAction) dacalCloseDoor: (id) sender
{
	DACALCommandCloseDoor([self dacalGetDeviceRef]);
}

-(IBAction) unMountClick: (id) sender
{
	
}

-(IBAction)drivePopupChanged   : (id)sender {}
-(IBAction)driveMountClicked   : (id)sender {}

-(IBAction)driveUnmountClicked : (id)sender {
	MediaDevice * selectedDevice = [self selectedDevice];
	if (selectedDevice) {
		
	}
}

-(IBAction)driveEjectClicked   : (id)sender {
	NSInteger buttonIndex = [drivePopup indexOfSelectedItem];
	NSInteger driveCount = [[driveSource theDeviceList] count];
	if (driveCount) {
		NSMutableArray *drives = [driveSource theDeviceList];
		MediaDevice *drive = [drives objectAtIndex:buttonIndex];
	}
			
}

-(IBAction)volumePopupChanged   : (id)sender {

}

-(IBAction)volumeUnmountClicked : (id)sender {

}

static int prevSlot;
-(IBAction) slotTextDidChange:(id) sender;
{
	int slot = [sender intValue];
	if (slot != prevSlot) {
		prevSlot = slot;
		[self dacalGotoClicked: sender];
	}
}

-(void)dacalSlotNumberEntered: (id) aNotification
{
}
													
													
@end