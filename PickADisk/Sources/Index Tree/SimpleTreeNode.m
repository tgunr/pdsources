/*
    SimpleTreeNode.m
    Copyright (c) 2001-2006, Apple Computer, Inc., all rights reserved.
    Author: Chuck Pisula

    Milestones:
    Initially created 3/1/01

    Tree node data structure carrying simple data (SimpleTreeNode, and SimpleNodeData).
*/

/*
 IMPORTANT:  This Apple software is supplied to you by Apple Computer, Inc. ("Apple") in
 consideration of your agreement to the following terms, and your use, installation, 
 modification or redistribution of this Apple software constitutes acceptance of these 
 terms.  If you do not agree with these terms, please do not use, install, modify or 
 redistribute this Apple software.
 
 In consideration of your agreement to abide by the following terms, and subject to these 
 terms, Apple grants you a personal, non-exclusive license, under Apple’s copyrights in 
 this original Apple software (the "Apple Software"), to use, reproduce, modify and 
 redistribute the Apple Software, with or without modifications, in source and/or binary 
 forms; provided that if you redistribute the Apple Software in its entirety and without 
 modifications, you must retain this notice and the following text and disclaimers in all 
 such redistributions of the Apple Software.  Neither the name, trademarks, service marks 
 or logos of Apple Computer, Inc. may be used to endorse or promote products derived from 
 the Apple Software without specific prior written permission from Apple. Except as expressly
 stated in this notice, no other rights or licenses, express or implied, are granted by Apple
 herein, including but not limited to any patent rights that may be infringed by your 
 derivative works or by other works in which the Apple Software may be incorporated.
 
 The Apple Software is provided by Apple on an "AS IS" basis.  APPLE MAKES NO WARRANTIES, 
 EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, 
 MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS 
 USE AND OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
 
 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL OR CONSEQUENTIAL 
 DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS 
 OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, 
 REPRODUCTION, MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED AND 
 WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE), STRICT LIABILITY OR 
 OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

#import "SimpleTreeNode.h"
#import "PADIndexOperation.h"
#import "DACALTreeDataSource.h"
#import "pmsDACALUtility.h"

#define KEY_GROUPNAME	@"Group"
#define KEY_ENTRIES		@"Entries"

@implementation SimpleNodeData

- (id)initWithName:(NSString *)str isLeaf:(BOOL)leaf {
    if (self = [super init]) {
        name = [str retain];
        isLeaf = leaf;
        iconRep = nil;
        isExpandable = !isLeaf;
        isSelectable = isLeaf;    
		location = NULL;
		itemType = 0;
		itemDevice = (DACALDeviceRef)NULL;
		itemSlot = 0;
    }
    return self;
}

- (id)initWithLocation:(NSURL *)loc {

	BOOL	isAFolder = (CFURLHasDirectoryPath((CFURLRef)loc)) ? YES : NO;

    if (self = [super init]) {
        location = [loc retain];
		name = (NSString*)CFURLCopyDisplayName( NULL, (CFURLRef)loc, NULL);
        isLeaf = !isAFolder;
        iconRep = CFURLGetIconAsNSImage( NULL, (CFURLRef)loc, NULL);
        isExpandable = isAFolder;
        isSelectable = YES;    
		itemType = 0;
		itemDevice = CFURLCopyCarouselUUID( (CFURLRef)loc );
		itemSlot = CFURLGetSlotNumber( (CFURLRef)loc, FALSE );
    }
    return self;
}

- (id)initWithLocation:(NSURL *)loc isLeaf:(BOOL)leaf {

    if (self = [super init]) {
        location = [loc retain];
		name = (NSString*)CFURLCopyDisplayName( NULL, (CFURLRef)loc, NULL);
        isLeaf = leaf;
        iconRep = CFURLGetIconAsNSImage( NULL, (CFURLRef)loc, NULL);
        isExpandable = !leaf;
        isSelectable = YES;    
 		itemType = 0;
		itemDevice = CFURLCopyCarouselUUID( (CFURLRef)loc );
		itemSlot = CFURLGetSlotNumber( (CFURLRef)loc, FALSE );
   }
    return self;
}

+ (id)leafDataWithName:(NSString*)str {
    // Convenience method to return a leaf node with its name set.
    return [[[SimpleNodeData alloc] initWithName:str isLeaf:YES] autorelease];
}

+ (id)groupDataWithName:(NSString*)str {
    // Convenience method to return a branch node with its name set.
    return [[[SimpleNodeData alloc] initWithName:str isLeaf:NO] autorelease];
}

+ (id)nodeDataWithURL:(NSURL*)loc {
    // Convenience method to return a leaf node with its location set.
    return [[[SimpleNodeData alloc] initWithLocation:loc] autorelease];
}

+ (id)nodeDataWithURL:(NSURL*)loc isLeaf:(BOOL)leaf {
    // Convenience method to return a leaf node with its location set.
    return [[[SimpleNodeData alloc] initWithLocation:loc isLeaf:leaf] autorelease];
}

- (void)dealloc {
    [name release];
    [iconRep release];
    [super dealloc];
}

- (void)setName:(NSString *)str { 
    if (!name || ![name isEqualToString:str]) {
	[name release]; 
	name = [str retain]; 
    }
}

- (NSString *)name { 
    return name; 
}

- (void)setIsLeaf:(BOOL)leaf { 
    isLeaf = leaf; 
}

- (BOOL)isLeaf { 
    return isLeaf; 
}

- (BOOL)isGroup { 
    return !isLeaf; 
}

- (void)setIconRep:(NSImage *)ir {
    if (!iconRep || ![iconRep isEqual:ir]) {
	[iconRep release];
	iconRep = [ir retain];
    }
}
- (NSImage *)iconRep {
    return iconRep;
}

- (void)setExpandable:(BOOL)value {
    isExpandable = value;
}

- (BOOL)isExpandable {
    return isExpandable;
}

- (BOOL)isSelectable {
    return isSelectable;
}

- (void)setSelectable:(BOOL)value {
    isSelectable = value;
}

- (NSString *)description { 
    return name; 
}

/*
- (NSComparisonResult)compare:(id)other {
    // We want the data to be sorted by name, so we compare [self name] to [other name]
    if ([other isKindOfClass:[SimpleNodeData class]]) {
        SimpleNodeData *_other = (SimpleNodeData *)other;
        return [name compare:[_other name]];
    } else {
        return NSOrderedAscending;
    }
}
*/

- (void)setLocation:(NSURL *)loc {
    if (!location || ![location isEqual:loc]) {
		[loc retain];
		[location release];
		location = loc;
    }
}
- (NSURL *)location {
    return location;
}
- (void)setLocationForIcon:(NSURL *)loc {
	// A convience function to set the url data and grab the icon
	
	[self setLocation:loc];
	[self setIconRep: [[NSImage alloc]initByReferencingURL:loc]];
	[self setName: (NSString*)CFURLCopyDisplayName( NULL, (CFURLRef)loc, NULL)];
}

- (void)setItemDevice:(DACALDeviceRef)device {
	CFURLRef oldDevice = (CFURLRef)itemDevice;

	if( !oldDevice || (!CFEqual(oldDevice, (CFURLRef)device)) )
	{
		if( oldDevice != NULL ) CFRelease( oldDevice );
		if( (CFURLRef)device != NULL ) CFRetain( (CFURLRef)device );
		itemDevice = device;
	}

}

- (DACALDeviceRef)itemDevice { return itemDevice; }

- (void)setItemSlot:(DACALSlotNum)slot { itemSlot = slot; }
- (DACALSlotNum)itemSlot { return itemSlot; }

- (void)setItemType:(NSInteger)type { itemType = type; }
- (NSInteger)itemType { return itemType; }

- (void)setSubTree:(SimpleTreeNode*)tree {
    if (!subTree || ![location isEqual:tree]) {
	[subTree release];
	subTree = [tree retain];
    }
}

- (SimpleTreeNode*)subTree { return subTree; }

- (BOOL)busy { return isBusy; }
- (void)setBusy:(BOOL)value { isBusy = value; }


-(NSComparisonResult)compareDataNames:(SimpleNodeData *)other
{
	NSLog(@"COMPARE NAME");
	return( [[self name] localizedCaseInsensitiveCompare:(NSString*)[other name]] );
}

-(NSComparisonResult)compareDataSlots:(SimpleNodeData *)other
{
	DACALSlotNum	thisSlot = [self itemSlot];
	DACALSlotNum	thatSlot = [other itemSlot];
	
//	NSLog(@"COMPARE SLOT");
	if( thisSlot == thatSlot ) return NSOrderedSame;
	if( thisSlot < thatSlot ) return NSOrderedAscending;
	return NSOrderedDescending;
}

- (NSComparisonResult)compare:(id)otherData
{ 
	NSComparisonResult		slotResult = NSOrderedAscending;
	
	if ([otherData isKindOfClass:[SimpleNodeData class]]) {
		SimpleNodeData *other = (SimpleNodeData *)otherData;
		slotResult = [self compareDataSlots:other]; 
		if(slotResult == NSOrderedSame)
			slotResult = [name compare:[other name] options:NSNumericSearch+NSCaseInsensitiveSearch];; // [self compareDataNames:other];
	}
	
	return slotResult;
}

@end

@implementation SimpleTreeNode

- (id)init
{
	if (![super init]) return nil;

	return self;
}

- (id)initFromDictionary:(NSDictionary*)dict {
    // This is a convenience init method to return a tree root of a tree derived from an input dictionary.
    // The input dictionary for this example app is InitInfo.dict.  Look at that file to understand the format.
    SimpleNodeData *data = [SimpleNodeData groupDataWithName:[dict objectForKey:KEY_GROUPNAME]];
    NSEnumerator *entryEnum = [[dict objectForKey:KEY_ENTRIES] objectEnumerator];
    id entry;
    SimpleTreeNode *child = nil;
	NSString*	entryName;
	NSString*	entryIconType; 
    
    self = [super initWithData:data parent:nil children:[NSArray array]];
    if (self != nil) {
        while ((entry = [entryEnum nextObject])) {
			
            if ([entry isKindOfClass: [NSDictionary class]])
                child = [SimpleTreeNode treeFromDictionary:entry];
			else if ([entry isKindOfClass: [NSArray class]]) {
				entryName = [entry objectAtIndex:0];
				entryIconType = [entry objectAtIndex:1];
				child = [[[SimpleTreeNode alloc] initWithData:[SimpleNodeData leafDataWithName:entryName] parent:nil children:[NSArray array]] autorelease];
				[[child nodeData] setIconRep: DACALGetIconImageForType( UTGetOSTypeFromString( (CFStringRef)entryIconType ) )];
			} else 
                child = [[[SimpleTreeNode alloc] initWithData:[SimpleNodeData leafDataWithName:entry] parent:nil children:[NSArray array]] autorelease];
            [self insertChild: child atIndex: [self numberOfChildren]];
        }
    }
    
    return self;
}

- (id)initFromLocation:(NSURL*)loc
{
    // This is a convenience init method to return a tree root of a tree derived from a filesystem URL.
    // This version uses treeFromLocation and is called from the Indexing NSOperation for speedy collections in most cases. 
    //SimpleNodeData *data = [SimpleNodeData nodeDataWithURL:loc];
	
	CFDictionaryRef		dataDict = NULL;
	CFArrayRef			dataProps = CFArrayCreate(NULL, (const void**)&kCFURLFileDirectoryContents, 1, &kCFTypeArrayCallBacks);
	CFArrayRef			folderList = NULL;
	Boolean				wasFound = FALSE;
	Boolean				isSlot = CFURLIsSlot( (CFURLRef)loc );
	
	wasFound = CFURLCreateDataAndPropertiesFromResource(NULL, (CFURLRef)loc, NULL, &dataDict, dataProps, NULL);
	if( wasFound ) {
		folderList = (CFArrayRef)CFDictionaryGetValue( dataDict, kCFURLFileDirectoryContents );
		if( folderList != NULL ) CFRetain( folderList );
		CFRelease( dataDict );
	}

	if( isSlot ) {
		if( (folderList != NULL ) && (CFArrayGetCount(folderList) > 0) ) {
			//data = [self nodeData];
			CFRelease( folderList );
			wasFound = CFURLCreateDataAndPropertiesFromResource(NULL, (CFURLRef)loc, NULL, &dataDict, dataProps, NULL);
			if( wasFound ) {
				folderList = (CFArrayRef)CFDictionaryGetValue( dataDict, kCFURLFileDirectoryContents );
				if( folderList != NULL ) CFRetain( folderList );
				CFRelease( dataDict );
			}
		}
	}
	
    NSEnumerator *entryEnum = [(NSArray*)folderList objectEnumerator];
    id entry;
    SimpleTreeNode *child = nil;
    
    if( [self nodeData] == nil ) self = [super initWithData:[SimpleNodeData nodeDataWithURL:loc] parent:nil children:[NSArray array]]; // [super initWithData:data parent:nil children:[NSArray array]];
    if (self != nil) {
        while ((entry = [entryEnum nextObject])) {
			if( CFURLIsVisible((CFURLRef)entry) ) {
				if (CFURLHasDirectoryPath((CFURLRef)entry))
					child = [SimpleTreeNode treeFromLocation:entry];
				else 
					child = [[[SimpleTreeNode alloc] initWithData:[SimpleNodeData nodeDataWithURL:entry] parent:nil children:[NSArray array]] autorelease];
				[self insertChild: child atIndex: [self numberOfChildren]];
			}
        }
    }
    
	CFRelease( dataProps );
	if( folderList != NULL ) CFRelease( folderList );
	
    return self;
}

- (id)initOperationFromLocation:(NSURL*)loc
{
    // This is a convenience init method to return a tree root of a tree derived from a filesystem URL.
    // This version uses treeOperationFromLocation and is therefore very unsuitable for recursive filesets
   // SimpleNodeData *data = nil;
	
	CFDictionaryRef		dataDict = NULL;
	CFArrayRef			dataProps = CFArrayCreate(NULL, (const void**)&kCFURLFileDirectoryContents, 1, &kCFTypeArrayCallBacks);
	CFArrayRef			folderList = NULL;
	Boolean				wasFound = FALSE;
	Boolean				isSlot = CFURLIsSlot( (CFURLRef)loc );
	
	wasFound = CFURLCreateDataAndPropertiesFromResource(NULL, (CFURLRef)loc, NULL, &dataDict, dataProps, NULL);
	if( wasFound ) {
		folderList = (CFArrayRef)CFDictionaryGetValue( dataDict, kCFURLFileDirectoryContents );
		if( folderList != NULL ) CFRetain( folderList );
		CFRelease( dataDict );
	}
	
	if( isSlot ) {
		if( CFArrayGetCount(folderList) > 0 ) {
			//data = [self nodeData];
			CFRelease( folderList );
			wasFound = CFURLCreateDataAndPropertiesFromResource(NULL, (CFURLRef)loc, NULL, &dataDict, dataProps, NULL);
			if( wasFound ) {
				folderList = (CFArrayRef)CFDictionaryGetValue( dataDict, kCFURLFileDirectoryContents );
				if( folderList != NULL ) CFRetain( folderList );
				CFRelease( dataDict );
			}
		}
	} //else data = [SimpleNodeData nodeDataWithURL:loc];
	
    NSEnumerator *entryEnum = [(NSArray*)folderList objectEnumerator];
    id entry;
    SimpleTreeNode *child = nil;
    
    if( [self nodeData] == nil ) self = [super initWithData:[SimpleNodeData nodeDataWithURL:loc] parent:nil children:[NSArray array]];
    if (self != nil) {
        while ((entry = [entryEnum nextObject])) {
			if( CFURLIsVisible((CFURLRef)entry) ) {
				if (CFURLHasDirectoryPath((CFURLRef)entry))
					child = [SimpleTreeNode treeOperationFromLocation:entry];
				else 
					child = [[[SimpleTreeNode alloc] initWithData:[SimpleNodeData nodeDataWithURL:entry] parent:nil children:[NSArray array]] autorelease];
				[self insertChild: child atIndex: [self numberOfChildren]];
			}
        }
    }

	CFRelease( dataProps );
	CFRelease( folderList );
	
    return self;
}

+ (id)nodeDataWithURL:(NSURL*)loc {
    // Convenience method to return a leaf node with its location set.
	return [[[SimpleTreeNode alloc] initWithData:[SimpleNodeData nodeDataWithURL:loc] parent:nil children:[NSArray array]] autorelease];
}


+ (id)treeFromDictionary:(NSDictionary *)dict {
    return [[[SimpleTreeNode alloc] initFromDictionary:dict] autorelease];
}

+ (id)treeFromLocation:(NSURL *)loc {
    return [[[SimpleTreeNode alloc] initFromLocation:loc] autorelease];
}

+ (id)treeOperationFromLocation:(NSURL *)loc
{
	SimpleTreeNode*		ourNode = [[SimpleTreeNode alloc] initWithData:[SimpleNodeData nodeDataWithURL:loc] parent:nil children:[NSArray array]];// [SimpleTreeNode nodeDataWithURL:loc];

	self = ourNode;	

	PADIndexOperation *indexOp = [[PADIndexOperation alloc] initWithLocation:loc forChild:ourNode];
	[[AppController shared] queueOperation:indexOp];
	[indexOp release];
	
    return self;
}


- (void)setDataDeviceAndSlotFromData:(id)data
{
	//Do Self
	[[self nodeData] setItemDevice:[data itemDevice]];
	[[self nodeData] setItemSlot:[data itemSlot]];
	
	[[self children] makeObjectsPerformSelector:@selector(setDataDeviceAndSlotFromData:) withObject:data];
}

- (void)setDataDevice:(DACALDeviceRef)inDevice slot:(DACALSlotNum)inSlot
{
	//Do Self
	[[self nodeData] setItemDevice:inDevice];
	[[self nodeData] setItemSlot:inSlot];
	
	[[self children] makeObjectsPerformSelector:@selector(setDataDeviceAndSlotFromData:) withObject:[self nodeData]];
}

- (BOOL)busy 
{
	return [[self nodeData] busy]; 
}

- (void)setBusy:(BOOL)value 
{ 
	BOOL	isBusy = [[self nodeData] busy];
	if( isBusy == value ) return;
	
	[[self nodeData] setBusy:value];
	isBusy = value;
	
	if( isBusy == YES )
	{	//NSLog(@"%@:Got Busy",self);
		[[AppController shared]	performSelectorOnMainThread:@selector(scheduleAddBusyBody:)
												 withObject:self
											  waitUntilDone:NO];
	} else {
		//NSLog(@"%@:Not Busy",self);
		[[AppController shared]	performSelectorOnMainThread:@selector(scheduleRemoveBusyBody:)
												 withObject:self
											  waitUntilDone:NO];		
	}
}

- (SimpleTreeNode*)childWithName:(NSString*)theName
{
	SimpleTreeNode*		outFoundNode = nil;
	SimpleTreeNode*		testChildNode = nil;
	UInt32	headCount = [self numberOfChildren];
	UInt32	childIndex = 0;
	
	for( childIndex=0; childIndex < headCount; childIndex++ )
	{
		testChildNode = (SimpleTreeNode*)[self childAtIndex:childIndex];
		if( CFEqual((CFStringRef)[[testChildNode nodeData] name], (CFStringRef)theName) )
		{
			outFoundNode = testChildNode;
			goto FOUND;
		}
	}
	
FOUND:
	return( outFoundNode );
}

- (SimpleTreeNode*)childWithDevice:(DACALDeviceRef)theBoxRef
{
	SimpleTreeNode*		outFoundNode = nil;
	SimpleTreeNode*		testChildNode = nil;
	UInt32	headCount = [self numberOfChildren];
	UInt32	childIndex = 0;
	
	for( childIndex=0; childIndex < headCount; childIndex++ )
	{
		testChildNode = (SimpleTreeNode*)[self childAtIndex:childIndex];
		if( CFEqual((CFUUIDRef)[[testChildNode nodeData] itemDevice], (CFUUIDRef)theBoxRef) )
		{
			outFoundNode = testChildNode;
			goto FOUND;
		}
	}
	
FOUND:
	return( outFoundNode );
}

- (SimpleTreeNode*)childWithSlotNum:(DACALSlotNum)theSlotNum
{
	SimpleTreeNode*		outFoundNode = nil;
	SimpleTreeNode*		testChildNode = nil;
	UInt32	headCount = [self numberOfChildren];
	UInt32	childIndex = 0;
	
	for( childIndex=0; childIndex < headCount; childIndex++ )
	{
		testChildNode = (SimpleTreeNode*)[self childAtIndex:childIndex];
		if( [[testChildNode nodeData] itemSlot] == theSlotNum ) 
		{
			outFoundNode = testChildNode;
			goto FOUND;
		}
	}
	
FOUND:
	return( outFoundNode );
}

- (SimpleTreeNode*)childWithItemType:(NSInteger)theItemType
{
	SimpleTreeNode*		outFoundNode = nil;
	SimpleTreeNode*		testChildNode = nil;
	UInt32	headCount = [self numberOfChildren];
	UInt32	childIndex = 0;
	
	for( childIndex=0; childIndex < headCount; childIndex++ )
	{
		testChildNode = (SimpleTreeNode*)[self childAtIndex:childIndex];
		if( [[testChildNode nodeData] itemType] == theItemType ) 
		{
			outFoundNode = testChildNode;
			goto FOUND;
		}
	}
	
FOUND:
	return( outFoundNode );
}



@end

