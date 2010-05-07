//
//  PADIndexOperation.m
//  PickADisc
//
//  Created by Jack Small on 7/15/08.
//  Copyright 2008 polyMicro Systems. All rights reserved.
//

#import "PADIndexOperation.h"
#import "PADSearchRequest.h"
#import "SimpleTreeNode.h"
#import "DACALDeviceNode.h"

@class PADSearchService;

@implementation PADIndexOperation

@synthesize subtreeChild;
@synthesize itemLocation;
@synthesize finishTarget;

- (id)initWithLocation:(NSURL*)url forChild:(SimpleTreeNode*)child completionTarget:(id)target;
{
    if( self = [super init] )
	{
		[self setSubtreeChild:child];
		[self setItemLocation:url];
		[self setFinishTarget:target];
		[child setBusy:YES];
	}
    return self;
}


- (id)initWithLocation:(NSURL*)url forChild:(SimpleTreeNode*)child;
	{ return [self initWithLocation:url forChild:child completionTarget:nil]; }

- (void)dealloc
{
    [subtreeChild release],	subtreeChild = nil;
    [itemLocation release],	itemLocation = nil;
    [finishTarget release],	finishTarget = nil;
    [super dealloc];
}

- (BOOL)cancelOperationForDevice:(DACALDevice*)oldBox
{
	DACALDeviceRef		ourBox = CFURLCopyCarouselUUID( kCFAllocatorDefault, (CFURLRef)itemLocation );
	BOOL				sameBox = [oldBox isDeviceRef:ourBox]; // [oldBox isEqual:DACALDeviceNodeForDeviceRef( ourBox )];
	
	if( ourBox != kDACALNullDevice ) CFRelease( (CFTypeRef)ourBox );
	else sameBox = YES;
	
	if( sameBox == YES )
		[self cancel];
	
	return sameBox;
}

- (void)main
{
	SimpleTreeNode*		theNode = [self subtreeChild];
	id					theTarget = [self finishTarget];
	
	if( [self isCancelled] ) return;
	
//	[theNode setBusy:YES];
	[theNode initFromLocation:[self itemLocation]];

	if( [self isCancelled] ) return;

	[theNode setBusy:NO];

	if( [self isCancelled] ) return;
	[PADSearchService updateAllSearches];
	
#ifdef __DCDEBUG
	NSLog(@"Finished location: %@", itemLocation);
#endif
	
	if( [self isCancelled] ) return;

	if( theTarget != nil )
		[theTarget	performSelectorOnMainThread:@selector(subTreeCompletedLoad:)
									 withObject:subtreeChild
								  waitUntilDone:NO];
}

@end
