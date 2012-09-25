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
 terms, Apple grants you a personal, non-exclusive license, under Apple‚Äö√Ñ√¥s copyrights in 
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
#import "PADSearchRequest.h"
#import <PMUtility/NSDate_Extensions.h>
#import "DACALTreeDataSource.h"
#import "DACALSlotElement.h"

@implementation SimpleTreeNode

- (id)init
{
	if (![super init]) return nil;
    
	return self;
}

-(id)initWithData:(id)data
{
	self = [super initWithData:data parent:nil children:[[NSArray alloc] init]];
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
    
    self = [super initWithData:data parent:nil children:[[NSArray alloc] init]];
    if (self != nil) {
        while ((entry = [entryEnum nextObject])) {
			
            if ([entry isKindOfClass: [NSDictionary class]])
                child = [SimpleTreeNode treeFromDictionary:entry];
			else if ([entry isKindOfClass: [NSArray class]]) {
				entryName = [entry objectAtIndex:0];
				entryIconType = [entry objectAtIndex:1];
				child = [[SimpleTreeNode alloc] initWithData:[SimpleNodeData leafDataWithName:entryName] parent:nil children:[[NSArray alloc] init]];
				[[child nodeData] setIconRep: DACALGetIconImageForType( UTGetOSTypeFromString( (CFStringRef)entryIconType ) )];
			} else
                child = [[SimpleTreeNode alloc] initWithData:[SimpleNodeData leafDataWithName:entry] parent:nil children:[[NSArray alloc] init]];
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
	DACALSlotElement*	ourElement = DACALDeviceSlotElementForURL( (CFURLRef)loc );
	DACALSlotElement*	anElement = nil;
	
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
    
    if( [self nodeData] == nil )
	    self = [super initWithData:[SimpleNodeData nodeDataWithURL:loc] parent:nil children:[[NSArray alloc] init]]; // [super initWithData:data parent:nil children:[NSArray array]];
    if (self != nil) {
		[ourElement setElementNode:self];
		[[self nodeData] setItemElement:ourElement];
		anElement = [DACALSlotElement slotElementForNode:self];
        while ((entry = [entryEnum nextObject])) {
			if( CFURLIsVisible((CFURLRef)entry) ) {
				if (CFURLHasDirectoryPath((CFURLRef)entry)) {
					PMLOG(PMLogLevelDebug3, @"tree: %@", entry);
					child = [SimpleTreeNode treeFromLocation:entry];
				}
				else
				{
					PMLOG(PMLogLevelDebug3, @"entry: %@", entry);
					child = [[SimpleTreeNode alloc] initWithData:[SimpleNodeData nodeDataWithURL:entry] parent:nil children:[[NSArray alloc] init]];
					anElement = [DACALSlotElement slotElementForNode:child];
				}
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
    
    if( [self nodeData] == nil ) self = [super initWithData:[SimpleNodeData nodeDataWithURL:loc] parent:nil children:[[NSArray alloc] init]];
    if (self != nil) {
        while ((entry = [entryEnum nextObject])) {
			if( CFURLIsVisible((CFURLRef)entry) ) {
				if (CFURLHasDirectoryPath((CFURLRef)entry))
					child = [SimpleTreeNode treeOperationFromLocation:entry];
				else
					child = [[SimpleTreeNode alloc] initWithData:[SimpleNodeData nodeDataWithURL:entry] parent:nil children:[[NSArray alloc] init]];
				[self insertChild: child atIndex: [self numberOfChildren]];
			}
        }
    }
    
	CFRelease( dataProps );
	CFRelease( folderList );
	
    return self;
}

- (void)dealloc {
    [self setBusy:NO];
    [super dealloc];
}

+ (id)nodeDataWithURL:(NSURL*)loc {
    // Convenience method to return a leaf node with its itemURL set.
	return [[SimpleTreeNode alloc] initWithData:[SimpleNodeData nodeDataWithURL:loc] parent:nil children:[NSArray array]];
}


+ (id)treeFromDictionary:(NSDictionary *)dict {
    return [[SimpleTreeNode alloc] initFromDictionary:dict];
}

+ (id)treeFromLocation:(NSURL *)loc {
    return [[SimpleTreeNode alloc] initFromLocation:loc];
}

+ (SimpleTreeNode *)treeOperationFromLocation:(NSURL *)loc forUI:(BOOL)uiQueue
{
	SimpleTreeNode*		ourNode = [[SimpleTreeNode alloc] initWithData:[SimpleNodeData nodeDataWithURL:loc] parent:nil children:[[NSArray alloc] init]];// [SimpleTreeNode nodeDataWithURL:loc];
    
	PADIndexOperation *indexOp = [[PADIndexOperation alloc] initWithLocation:loc forChild:ourNode];
	if( uiQueue )
        [[AppController shared] queueUIOperation:indexOp];
	else
        [[AppController shared] queueOperation:indexOp];
    
	[indexOp release];
	
    return ourNode;
}

+ (id)treeOperationFromLocation:(NSURL *)loc
{
	return [SimpleTreeNode treeOperationFromLocation:loc forUI:NO];
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
	
	isBusy = value;
	
	if( isBusy == YES )
	{	//NSLog(@"%@:Got Busy",self);
		[[AppController shared]	performSelectorOnMainThread:@selector(scheduleAddBusyBody:)
												 withObject:self
											  waitUntilDone:YES];
	} else {
		//NSLog(@"%@:Not Busy",self);
		[[AppController shared]	performSelectorOnMainThread:@selector(scheduleRemoveBusyBody:)
												 withObject:self
											  waitUntilDone:NO];
	}
	[[self nodeData] setBusy:value];
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

- (NSNumber*)numberForSlotNumber
{ return [[self nodeData] numberForSlotNumber]; }

-(SimpleNodeData*)keyName { return [self nodeData]; }
-(SimpleNodeData*)keySlotNumber { return [self nodeData]; }
-(SimpleNodeData*)keyAddDate { return [self nodeData]; }
-(SimpleNodeData*)keyFlavor { return [self nodeData]; }
-(SimpleNodeData*)keyCheckedOut { return [self nodeData]; }
-(SimpleNodeData*)keyCheckedOutDate { return [self nodeData]; }
-(SimpleNodeData*)keyComments { return [self nodeData]; }
-(SimpleNodeData*)keyTags { return [self nodeData]; }
-(SimpleNodeData*)keyStars { return [self nodeData]; }
-(void)setKeyStars:(NSInteger)starLevel
{ [[self nodeData] setKeyStars:starLevel]; }

-(SimpleTreeNode*)matchActual
{
	SimpleTreeNode*		realNode = [[self nodeData] matchActual];
	
	if( realNode == nil )
		realNode = self;
	
	return realNode;
}

- (NSString*)localPathName { return [[self nodeData] name]; }

- (NSString*)localPathString {
	
	if( [[self nodeData] itemDevice] == kDACALNullDevice )
        return nil;
	
	NSString*				outName = nil;
	NSMutableString*		workNames = [NSMutableString stringWithCapacity:0];
	SimpleTreeNode*			aParent = (SimpleTreeNode*)self;	//[self nodeParent];
	
	while ([aParent nodeParent] != nil) {
		[workNames setString:[NSString stringWithFormat:@"%@/%@",[aParent localPathName],workNames]];
		aParent = (SimpleTreeNode*)[aParent nodeParent];
	}
	
	if( [workNames length] > 0 )
		outName = [workNames substringToIndex:[workNames length]-1];
	
	return outName;
}

- (NSString*)absolutePathName
{
	NSString*	outName = nil;
	CFStringRef	workName = CFURLCopyActualName( kCFAllocatorDefault, (CFURLRef)[(SimpleNodeData*)[self nodeData] itemURL], NULL );
	
	if( workName != NULL )
	{
		outName = [NSString stringWithString:(NSString*)workName];
		CFRelease( workName );
	}
	
	return outName;
}

- (NSString*)absolutePathString
{
	if( [[self nodeData] itemDevice] == kDACALNullDevice ) return nil;
	
	NSString*				outName = nil;
	NSMutableString*		workNames = [NSMutableString stringWithCapacity:0];
	SimpleTreeNode*			aParent = [self matchActual];
	CFURLRef				aSpot = (CFURLRef)[(SimpleNodeData*)[aParent nodeData] itemURL];
	
	if( CFURLIsTopInSlot( kCFAllocatorDefault, aSpot ) || CFURLIsSlot( aSpot ) )
		[workNames setString:@"/"];
	else
		while ([aParent nodeParent] != nil) {
			[workNames setString:[NSString stringWithFormat:@"%@/%@",[aParent absolutePathName],workNames]];
			aParent = (SimpleTreeNode*)[aParent nodeParent];
			aSpot = (CFURLRef)[(SimpleNodeData*)[aParent nodeData] itemURL];
			if( CFURLIsTopInSlot( kCFAllocatorDefault, aSpot ) || CFURLIsSlot( aSpot ) ) break;
		}
	
	if( [workNames length] > 0 ) outName = [workNames substringToIndex:[workNames length]-1];
	else outName = nil;
	
	return outName;
}

- (NSString *)description
{
	
	if( [[self nodeData] itemDevice] == kDACALNullDevice ) return [[self nodeData] name];
	if( [[self nodeData] itemSlot] == 0 ) return [[self nodeData] name];
	
	NSString*			localPath = [self localPathString];
	NSString*			localDevice = (NSString*)DACALCommandCopyName([[self nodeData] itemDevice], NULL );
	NSString*			outString = [NSString stringWithFormat:NSLocalizedString(@"“%@” Slot %i: %@", @"Element Node Description Format with device, slot num and item path"), localDevice, [[self nodeData] itemSlot], localPath];
    
	[localDevice release];
    return outString;
}

- (NSString*)urlString
{
	
	if( [[self nodeData] itemDevice] == kDACALNullDevice ) return [[self nodeData] name];
	
	NSString*			localPath = [self localPathString];
	NSString*			localHost = @"";
	NSString*			localDevice = (NSString*)CFUUIDCreateString( kCFAllocatorDefault, (CFUUIDRef)[[self nodeData] itemDevice] );
	NSString*			urlString = [NSString stringWithFormat:@"carousel://%@/%@/%i/%@", localHost, localDevice, [[self nodeData] itemSlot], localPath];
	
	[localDevice release];
    return urlString;
}

- (NSString *)tooltip
{
	if( [[self nodeData] itemDevice] == kDACALNullDevice ) return [[self nodeData] name];
	if( [[self nodeData] itemSlot] == 0 ) return [[self nodeData] name];
	
	NSString*			localPath = [self localPathString];
	NSDate*				checkOutDate = [[self nodeData] checkedOutDate];
	NSString*			checkedOutString = NSLocalizedString(@"", @"Element Node Tooltip Format for items checked in");
	
	localPath = [[self matchActual] localPathString];
	
	if( checkOutDate != nil )
		checkedOutString = [NSString stringWithFormat:NSLocalizedString(@"Checked out on %@\n", @"Element Node Tooltip Format for date checked out"), [checkOutDate description]];
	
	NSString*			localDevice = (NSString*)DACALCommandCopyName([[self nodeData] itemDevice], NULL );
	NSString*			outString = [NSString stringWithFormat:NSLocalizedString(@"“%@” Slot %i\n%@%@", @"Element Node Tooltip Format for device name, slot num, checked out string, item path"), localDevice, [[self nodeData] itemSlot], checkedOutString, localPath];
	
	[localDevice release];
    return outString;
}


@end


