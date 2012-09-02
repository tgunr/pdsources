//
//  PADCarouselOperation.m
//  PickADisc
//
//  Copyright 2008 PolyMicro Systems. All rights reserved.
//

#import "PADCarouselOperation.h"
#import "AppController.h"
#import "DACALDevice.h"

@implementation PADOperationTask

- (DACALDevice *)theBoxRef {
	return theBoxRef;
}

- (void)setTheBoxRef: (DACALDevice *) newBox {
	if (newBox)
		[newBox retain];
	if (theBoxRef)
		[theBoxRef release];
	theBoxRef = newBox;
}

-(void)dealloc
{
	[self setTheBoxRef:nil];
	[super dealloc];
}

-(BOOL)newTaskForOperation:(PADCarouselOperation*)ownerOp
	{ return YES; }

-(void)queueTaskForOperation:(PADCarouselOperation*)ownerOp
	{ [[AppController shared] queueOperation:ownerOp]; }

-(BOOL)runTaskForOperation:(PADCarouselOperation*)ownerOp
{
	
	return YES; 
}

-(id)endTaskForOperation:(PADCarouselOperation*)ownerOp
	{ return (id)ownerOp; }


-(BOOL)cancelOperationForDevice:(DACALDevice*)oldBox
{
	return [[self theBoxRef] isEqual:oldBox];	//[oldBox isDeviceRef:[self theBoxRef]];
}

-(id)startNewOperationForTarget:(id)theTarget endSelector:(SEL)theSelector
{ return [PADCarouselOperation startOperationTask:self forTarget:theTarget endSelector:theSelector]; }

@end

@implementation PADCarouselOperation
@synthesize finishTarget;
@synthesize thisOperation;

-(SEL)finishSelector
{ return finishSelector; }
-(void)setFinishSelector:(SEL)newSel
{ finishSelector = newSel; }

-(id)init
{
	self = [super init];
	if(self)
	{
		canceled = NO;	
	}
	return self;
}

-(id)initWithTarget:(id)theTarget endSelector:(SEL)theSelector
{
	self = [self init];
	if(self)
	{
		finishTarget = theTarget;
		finishSelector = theSelector;
	}
	
	return self;
}

-(void)dealloc
{
	[self setFinishTarget:nil];
	[self setThisOperation:nil];
	
	[super dealloc];
}

-(BOOL)cancelOperationForDevice:(DACALDevice*)oldBox
{
	BOOL cancel = [[self thisOperation] cancelOperationForDevice:oldBox];
	
	if( cancel ) [self cancel];
	
	return cancel;
}

+(id)startOperationTask:(id)opTask forTarget:(id)opTarget endSelector:(SEL)theSelector
{
	PADCarouselOperation*	newTask = [[PADCarouselOperation alloc] initWithTarget:opTarget endSelector:theSelector];
	
	[newTask setThisOperation:opTask];
	if( [[newTask thisOperation] newTaskForOperation:newTask] )
		[[newTask thisOperation] queueTaskForOperation:newTask];
	else {
		[newTask release];
		newTask = nil;
	}
	
	return newTask;
}

-(void)main
{
	BOOL	finished = NO;
	id		theTarget = [self finishTarget];
	SEL		theSelector = [self finishSelector];
	id		returnValue = nil;
	
	while( !finished && ![self isCancelled] )
		finished = [[self thisOperation] runTaskForOperation:self];
	
	if( [self isCancelled] ) return;
	
	returnValue = [[self thisOperation] endTaskForOperation:self];

	if( [self isCancelled] ) return;
	
	if( (theTarget != nil) && (theSelector != nil) )
		[theTarget	performSelectorOnMainThread:theSelector
									withObject:returnValue
								 waitUntilDone:NO];
	
}

@end
