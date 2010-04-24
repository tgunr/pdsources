//
//  DACALDevice.m
//  PickADisk
//
//  Created by Jack Small on 9/3/08.
//  Copyright 2008 Jack Small. All rights reserved.
//

#import "DACALDevice.h"
#import "DACALDeviceSerivce.h"
#import "PADOperationOpenDevice.h"
//#import "PADOperationControlDevice.h"
//#import "LicenseService.h"
#import "IconFamily.h"
#import "dacalconstants.h"
//#import "DACDriverInstaller.h"
#import "NSArray_Extensions.h"
//#import "AppController.h"
//#import "DACALSlot.h"
#import "PADSearchRequest.h"
#import "DACALTreeDataSource.h"


CFStringRef		kPADClientIdentifier = CFSTR("PAD.DACAL.CLIENT");

//	Device Array

//NSMutableArray*		gDACALDevices;



@implementation DACALDevice

@synthesize deviceRef;
@synthesize deviceFSRef;
@synthesize boxName;
@synthesize boxURL;

-(void)dealloc
{
	if( deviceRef ) CFRelease( (CFTypeRef)deviceRef );	
	deviceRef = kDACALNullDevice;
	
	[super dealloc];
}

-(BOOL)isDeviceRef:(DACALDeviceRef)aDevice
{ 
	if( (aDevice==kDACALNullDevice) || (deviceRef==kDACALNullDevice) ) return NO;
	
	return (CFEqual((CFTypeRef)deviceRef, (CFTypeRef)aDevice )) ? YES : NO;
}


+(id)deviceWithDeviceRef:(DACALDeviceRef)newDeviceRef
	{ return [[DACALDevice alloc] initDeviceWithDeviceRef:newDeviceRef]; }

-(NSString*)title
	{ return( (NSString*)DACALCommandCopyName( deviceRef, NULL ) ); }

-(NSURL*)fileURL
	{ return( (NSURL*)DACALCommandCopyPath( deviceRef, NULL ) ); }

-(id)initDeviceWithDeviceRef:(DACALDeviceRef)newDeviceRef
{
	if( self = [super init] )
	{
		[self setDeviceRef: newDeviceRef];
				
//		int					tempIndex, tempCount = DACALCommandGetSlotCount( newDeviceRef );
//		NSMutableArray*		tempArray = [NSMutableArray arrayWithCapacity:tempCount];
		
//		for( tempIndex=0; tempIndex < tempCount; tempIndex++ )
//			[tempArray addObject:[DACALSlot createSlotForDevice:self inSlot:tempIndex+1]];
		
//		deviceSlots = [[NSArray alloc] initWithArray:tempArray];
		
		[self setBoxName: (NSString*)DACALCommandCopyName( newDeviceRef, NULL )];
		[self setBoxURL: DACALCommandCopyPath( newDeviceRef, NULL )];
		
		CFURLGetFSRef( boxURL, &deviceFSRef );
		

	}
	return self;	
}


-(DACALResult)commandCloseDoor
	{ return DACALCommandCloseDoor( deviceRef ); }

@end		// DACALDevice


