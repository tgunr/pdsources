//
//  PADIndexOperation.m
//  PickADisc
//
//  Created by Jack Small on 7/15/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "PADIndexOperation.h"

@implementation PADIndexOperation

@synthesize subtreeChild;
@synthesize itemLocation;
@synthesize finishTarget;

- (id)initWithLocation:(NSURL*)url forChild:(SimpleTreeNode*)child completionTarget:(id)target;
{
    if (![super init]) return nil;
	[self setSubtreeChild:child];
    [self setItemLocation:url];
	[self setFinishTarget:target];
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
	BOOL				sameBox = [oldBox isEqual:DACALDeviceForDeviceRef( ourBox )];
		
	if( ourBox ) CFRelease( (CFTypeRef)ourBox );
	
	return sameBox;
}

- (void)main
{
	SimpleTreeNode*		theNode = [self subtreeChild];
	id					theTarget = [self finishTarget];
	
	[theNode setBusy:YES];
	[theNode initFromLocation:[self itemLocation]];
	[theNode setBusy:NO];

#ifdef __DCDEBUG
	NSLog(@"Finished location: %@", itemLocation);
#endif
	
	if( theTarget != nil )
		[theTarget	performSelectorOnMainThread:@selector(subTreeCompletedLoad:)
									 withObject:subtreeChild
								  waitUntilDone:NO];
}

@end
