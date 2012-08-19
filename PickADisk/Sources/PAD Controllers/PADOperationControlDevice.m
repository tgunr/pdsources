//
//  PADOperationControlDevice.m
//  PickADisk
//
//  Copyright 2008 PolyMicro Systems. All rights reserved.
//

#import "PADOperationControlDevice.h"
#import "AppController.h"

@implementation PADOperationControlDevice

-(DACALSlotNum)workSlot
{ return workSlot; }
-(void)setWorkSlot:(DACALSlotNum)newSlot
{ workSlot = newSlot; }

-(DACALDeviceRef)otherDevice
{ return otherDevice; }
-(void)setOtherDevice:(DACALDeviceRef)newBox
{
	if( newBox ) CFRetain((CFTypeRef)newBox);
	if( otherDevice ) CFRelease((CFTypeRef)otherDevice);
	otherDevice = newBox; 
}

-(DACALSlotNum)otherSlot
{ return otherSlot; }
-(void)setOtherSlot:(DACALSlotNum)newSlot
{ otherSlot = newSlot; }

-(NSString*)ejectVolume
{ return ejectVolume; }
-(void)setEjectVolume:(NSString*)volumePath
{ 
	if( volumePath ) [volumePath retain];
	if( ejectVolume ) [ejectVolume release];
	ejectVolume = volumePath; 
}

-(id)init
{
	if( self = [super init] )
	{
		[self setTheBoxRef:nil];
		[self setWorkSlot:0];
		[self setOtherDevice:kDACALNullDevice];
		[self setOtherSlot:0];
		[self setEjectVolume:nil];
	}
	return self;
}

-(void)dealloc
{
	[self setTheBoxRef:nil];
	[self setWorkSlot:0];
	[self setOtherDevice:kDACALNullDevice];
	[self setOtherSlot:0];
	[self setEjectVolume:nil];
	
	[super dealloc];
}

-(id)initForBox:(DACALDevice*)newBox forSlot:(DACALSlotNum)newSlot ejectVolume:(NSString*)volumePath
{
	if( self = [self init] )
	{
		[self setTheBoxRef:newBox];
		[self setWorkSlot:newSlot];
		[self setEjectVolume:volumePath];
	}
	return self;
}

-(void)queueTaskForOperation:(PADCarouselOperation*)ownerOp
{ [[AppController shared] queueUIOperation:ownerOp]; }

-(BOOL)runTaskForOperation:(PADCarouselOperation*)ownerOp
{
	if( ([[NSUserDefaults standardUserDefaults] boolForKey:@"PADEjectOnIndex"] == YES ) && (ejectVolume != nil) )
		[[NSWorkspace sharedWorkspace] unmountAndEjectDeviceAtPath: ejectVolume];
	if( [ownerOp isCancelled] ) return YES;
	if( ([[NSUserDefaults standardUserDefaults] boolForKey:@"PADCheckInOnIndex"] == YES ) && (workSlot != 0) )
		DACALCommandMoveToSlotWithOptions( [theBoxRef deviceRef], workSlot, kDACALOptionMoveDefault );
	
	return YES; 
}

+(PADOperationControlDevice*)finishIndexingVolume:(NSString*)volumePath forSlot:(DACALSlotNum)newSlot onDevice:(DACALDevice*)newBox forTarget:(id)theTarget
{
	PADOperationControlDevice*	newSelf = [[PADOperationControlDevice alloc] initForBox:newBox forSlot:newSlot ejectVolume:volumePath];
	
	if( !newSelf ) return newSelf;
	
	return [newSelf startNewOperationForTarget:theTarget endSelector:@selector(indexDeviceControlFinished:)];
}



@end
