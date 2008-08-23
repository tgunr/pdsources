//
//  PADCarouselOperation.m
//  PickADisc
//
//  Created by Jack Small on 7/29/08.
//  Copyright 2008 Jack Small. All rights reserved.
//

#import "PADCarouselOperation.h"


@implementation PADOperationTask

-(DACALDeviceRef)theBoxRef
{ return theBoxRef; }
-(void)setTheBoxRef:(DACALDeviceRef)newBox
{
	if( newBox ) CFRetain((CFTypeRef)newBox);
	if( theBoxRef ) CFRelease((CFTypeRef)theBoxRef);
	theBoxRef = newBox; 
}

-(void)dealloc
{
	[self setTheBoxRef:kDACALNullDevice];
	[super dealloc];
}

-(BOOL)newTaskForOperation:(PADCarouselOperation*)ownerOp
	{ return YES; }
-(BOOL)runTaskForOperation:(PADCarouselOperation*)ownerOp
{
	
	return YES; 
}

-(id)endTaskForOperation:(PADCarouselOperation*)ownerOp
	{ return (id)ownerOp; }


-(BOOL)cancelOperationForDevice:(DACALDeviceRef)oldBox
{
	if( CFEqual( (CFTypeRef)oldBox, (CFTypeRef)[self theBoxRef] ) ) return YES;
	return NO; 
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
	if(self = [super init])
	{
		canceled = NO;	
	}
	return self;
}

-(id)initWithTarget:(id)theTarget endSelector:(SEL)theSelector
{
	if( self = [self init] )
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

-(BOOL)cancelOperationForDevice:(DACALDeviceRef)oldBox
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
		[[AppController shared] queueUIOperation:newTask];
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
	
	while( !finished )
		finished = [[self thisOperation] runTaskForOperation:self];
	
	returnValue = [[self thisOperation] endTaskForOperation:self];
	
	if( (theTarget != nil) && (theSelector != nil) )
		[theTarget	performSelectorOnMainThread:theSelector
									withObject:returnValue
								 waitUntilDone:NO];
	
}

@end
