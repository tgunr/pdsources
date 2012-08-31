//
//  DACALDeviceObjC.m
//  PickADisk
//
//  Copyright 2008 PolyMicro Systems. All rights reserved.
//

#import "DACALDeviceObjC.h"
#import "PADOperationOpenDevice.h"
#import "DACALDeviceService.h"

//	Device Array

void DACALNotification( void* inData, DACALDeviceRef inBox, CFStringRef inMessage, CFDictionaryRef inParam )
{
	DACALDeviceService*	deviceService = (DACALDeviceService*)inData;
	
	PMLOGINFO( @"Client Notification: Device: %@ Message: %@", inBox, inMessage );
	
	if( CFStringHasPrefix( inMessage, kDACALCarouselNoticeDeviceOpen ) )
		[deviceService notificationDeviceAttached:inBox];
	else if( CFStringHasPrefix( inMessage, kDACALCarouselNoticeDeviceClose ) )
		[deviceService notificationDeviceDetached:inBox];
}

DACALDevice*	DACALDeviceForDeviceRef(DACALDeviceRef aBoxRef)
	{ return [[DACALDeviceService sharedService] DACALDeviceForDeviceRef:aBoxRef]; }
 
DACALSlot*		DACALDeviceSlotForSlotNumber(DACALDeviceRef aBoxRef, DACALSlotNum aSlotNum)
	{ return [[DACALDeviceService sharedService] DACALDeviceSlotForDeviceRef:aBoxRef andSlotNum:aSlotNum]; }

DACALSlot*		DACALDeviceSlotForSlotIdentifier( CFStringRef findID )
	{ return [[DACALDeviceService sharedService] DACALDeviceSlotForSlotIdentifier:(NSString*)findID]; }

DACALSlotElement*	DACALDeviceSlotElementForURL( CFURLRef itemURL )
	{ return [[DACALDeviceService sharedService] DACALDeviceSlotElementForURL:(NSURL*)itemURL]; }


