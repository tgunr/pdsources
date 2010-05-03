//
//  DACALDevice.h
//  PickADisk
//
//  Created by Jack Small on 9/3/08.
//  Copyright 2008 Jack Small. All rights reserved.
//
#import "pmsDACALUtility.h"

extern CFStringRef kPADClientIdentifier;



@interface DACALDevice : NSObject {
	DACALDeviceRef deviceRef;
	FSRef          deviceFSRef;
	NSString*			boxName;
	CFURLRef			boxURL;
}

@property (assign) DACALDeviceRef deviceRef;
@property (assign) FSRef deviceFSRef;
@property (assign) NSString* boxName;
@property (assign) CFURLRef boxURL;

-(BOOL)isDeviceRef: (DACALDeviceRef) aDevice;

//- (NSUndoManager*)undoManager;

-(id)initDeviceWithDeviceRef: (DACALDeviceRef) newDeviceRef;
+(id)deviceWithDeviceRef: (DACALDeviceRef) newDeviceRef;

-(NSString *)title;
-(NSURL *)fileURL;

-(DACALResult)commandCloseDoor;

@end        //	DACALDevice

extern DACALDevice * DACALDeviceForDeviceRef(DACALDeviceRef aBoxRef);