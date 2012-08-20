//
//  DACALDeviceObjC.m
//  PickADisk
//
//  Copyright 2008 PolyMicro Systems. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <DACAL/pmsDACALUtility.h>
#import "SimpleTreeNode.h"
#import "DACVolume.h"

extern CFStringRef			kPADClientIdentifier;

@class DACALSlotElement;
@class DACALSlot;
@class DACALDevice;

extern DACALDevice*			DACALDeviceForDeviceRef(DACALDeviceRef aBoxRef);
extern DACALSlot*			DACALDeviceSlotForSlotNumber(DACALDeviceRef aBoxRef, DACALSlotNum aSlotNum);
extern DACALSlot*			DACALDeviceSlotForSlotIdentifier( CFStringRef findID );
extern DACALSlotElement*	DACALDeviceSlotElementForURL( CFURLRef itemURL );

extern void					DACALNotification( void* inData, DACALDeviceRef inBox, CFStringRef inMessage, CFDictionaryRef inParam );


