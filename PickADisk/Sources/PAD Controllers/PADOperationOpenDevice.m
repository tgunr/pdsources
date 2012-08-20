//
//  PADOperationOpenDevice.m
//  PickADisk
//
//  Copyright 2008 PolyMicro Systems. All rights reserved.
//

#import "PADOperationOpenDevice.h"
#import "DACALDevice.h"

@implementation PADOperationOpenDevice

-(SimpleTreeNode*)theDeviceNode
{ return theDeviceNode; }
-(void)setTheDeviceNode:(SimpleTreeNode*)newNode
{ theDeviceNode = newNode; }

-(void)dealloc
{
	[self setTheDeviceNode:nil];
	[self setTheBoxRef:nil];
	
	[super dealloc];
}

-(id)endTaskForOperation:(PADCarouselOperation*)ownerOp
{ 
	return (id)theBoxRef;
}

+(BOOL)addDeviceToSourceTree:(DACALDevice*)newBox
{
	PADOperationOpenDevice*	newSelf = [[PADOperationOpenDevice alloc] init];
	
	[newSelf setTheBoxRef:newBox];
	[newSelf setTheDeviceNode:[newBox deviceNode]];

	[newSelf startNewOperationForTarget:newBox endSelector:@selector(attachedDevice:)];
	return YES; 
}

-(BOOL)runTaskForOperation:(PADCarouselOperation*)ownerOp
{
	[[self theBoxRef] loadSlotIndex];
	
	return YES; 
}

@end
