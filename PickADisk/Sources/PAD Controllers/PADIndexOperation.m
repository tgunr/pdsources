//
//  PADIndexOperation.m
//  PickADisc
//
//  Copyright 2008 PolyMicro Systems. All rights reserved.
//

#import "PADIndexOperation.h"
#import "PADSearchRequest.h"
#import "DACALDevice.h"

@implementation PADIndexOperation

@synthesize subtreeChild;
@synthesize itemLocation;
@synthesize finishTarget;

- (id)initWithLocation:(NSURL*)url forChild:(SimpleTreeNode*)child completionTarget:(id)target;
{
	self = [super init];
	if(self)
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
	BOOL				sameBox = [oldBox isDeviceRef:ourBox]; // [oldBox isEqual:DACALDeviceForDeviceRef( ourBox )];
	
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
	
	if( [self isCancelled] )
        return;
	
//	[theNode setBusy:YES];
	[theNode initFromLocation:[self itemLocation]];

	if( [self isCancelled] )
        return;

	[theNode setBusy:NO];

	if( [self isCancelled] )
        return;
	[PADSearchService updateAllSearches];
	
	PMLOGDEBUG(@"Finished location: %@", itemLocation);
	
	if( [self isCancelled] )
        return;

	if( theTarget != nil )
		[theTarget	performSelectorOnMainThread:@selector(subTreeCompletedLoad:)
									 withObject:subtreeChild
								  waitUntilDone:NO];
}

@end
