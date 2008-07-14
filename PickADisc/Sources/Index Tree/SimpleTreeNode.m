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
 terms, Apple grants you a personal, non-exclusive license, under AppleÕs copyrights in 
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

Boolean	CFURLIsCarousel( CFURLRef url );
Boolean	CFURLIsCarousel( CFURLRef url )
{
	CFStringRef		itemName = CFURLCopyLastPathComponent( url );
	CFRange			foundRange = CFStringFind( itemName, CFSTR("Carousel "), 0 );
	
	CFRelease( itemName );
	return( foundRange.length != 0 );
}

Boolean	CFURLIsSlot( CFURLRef url );
Boolean	CFURLIsSlot( CFURLRef url )
{
	CFStringRef		itemName = CFURLCopyLastPathComponent( url );
	CFRange			foundRange = CFStringFind( itemName, CFSTR("Slot "), 0 );
	
	CFRelease( itemName );
	return( foundRange.length != 0 );
}



IconRef	CFURLGetIcon( CFAllocatorRef allocator, CFURLRef url, OSStatus* outError );
IconRef	CFURLGetIcon( CFAllocatorRef allocator, CFURLRef url, OSStatus* outError )
{
	FSRef			theFileRef;
	Boolean			isGoodFile = FALSE;
	OSStatus		outResult = paramErr;
	FSCatalogInfo	theCatInfo;
	HFSUniStr255	theFileName;
	SInt16			theFileLabel;
	
	IconRef			theOutputIcon = NULL;
	
	if( CFURLIsCarousel(url) ) {
		outResult = GetIconRef( kOnSystemDisk, 'DACi', 'Crsl', &theOutputIcon );
		if( outResult != 0 ) printf( "GetIconRef: %d\n", (int)outResult );
		AcquireIconRef(theOutputIcon);
		goto BAIL;
	}
	
	isGoodFile = CFURLGetFSRef( url, &theFileRef );
	if( !isGoodFile ) goto BAIL;	
	outResult = FSGetCatalogInfo(&theFileRef, kIconServicesCatalogInfoMask, &theCatInfo, &theFileName, NULL, NULL);
	if( outResult != 0 ) goto BAIL;
	outResult = GetIconRefFromFileInfo(&theFileRef, theFileName.length, (const UniChar*)&theFileName.unicode,
										kIconServicesCatalogInfoMask, &theCatInfo, kIconServicesNormalUsageFlag, 
										&theOutputIcon, &theFileLabel);
	
BAIL:
	if( outError != NULL ) *outError = outResult;
	return( theOutputIcon );
}

NSImage*	CFURLGetIconAsNSImage( CFAllocatorRef allocator, CFURLRef url, OSStatus* outError );
NSImage*	CFURLGetIconAsNSImage( CFAllocatorRef allocator, CFURLRef url, OSStatus* outError )
{
	IconRef	theItemIcon = CFURLGetIcon(allocator, url, outError);
	NSImage*	theItemImage = NULL;
	
	if( theItemIcon != NULL ) theItemImage = [[NSImage alloc]initWithIconRef:theItemIcon];
	if( theItemImage != NULL ) {
		[theItemImage setScalesWhenResized:YES];
		[theItemImage setSize:NSMakeSize( 16.0, 16.0 )];
		}
	
	return( theItemImage );
}

CFStringRef	CFURLCopyDisplayName( CFAllocatorRef allocator, CFURLRef url, OSStatus* outError )
{
	CFStringRef		theOutputName = NULL;
	OSStatus		theOutResult;
	
	theOutResult = 	LSCopyDisplayNameForURL(url, &theOutputName);

	if( outError != NULL ) *outError = theOutResult;
	return( theOutputName );
}	

/*	
{
	FSRef			theFileRef;
	Boolean			isGoodFile = FALSE;
	OSStatus		outResult = paramErr;
	FSCatalogInfo	theCatInfo;
	HFSUniStr255	theFileName;
	
	CFStringRef		theOutputName = NULL;
	
	isGoodFile = CFURLGetFSRef( url, &theFileRef );
	if( !isGoodFile ) goto BAIL;	
	outResult = FSGetCatalogInfo(&theFileRef, kFSCatInfoNone, &theCatInfo, &theFileName, NULL, NULL);
	if( outResult != 0 ) goto BAIL;

	theOutputName = CFStringCreateWithCharacters(allocator, (const UniChar*)&theFileName.unicode, theFileName.length);
		
BAIL:
	if( outError != NULL ) *outError = outResult;
	return( theOutputName );
}
*/


Boolean	CFURLIsVisible( CFURLRef url );
Boolean	CFURLIsVisible( CFURLRef url )
{
	Boolean				isURLVisible = FALSE;
	FSRef				theFileRef;
	Boolean				isGoodFile = FALSE;
	OSStatus			outResult;
	LSItemInfoRecord	theFileInfo;
		
	isGoodFile = CFURLGetFSRef( url, &theFileRef );
	if( !isGoodFile ) goto BAIL;	
	
	outResult = LSCopyItemInfoForRef( &theFileRef, kLSRequestBasicFlagsOnly, &theFileInfo );
	if( outResult == noErr ) isURLVisible = ((theFileInfo.flags & kLSItemInfoIsInvisible) == 0);
			
BAIL:
	return( isURLVisible );
}


NSImage*	DACALGetIconImageForType( int	theType )
{
	OSStatus		outResult = paramErr;
	IconRef			theOutputIcon = NULL;
	NSImage*		theOutputImage = NULL;
	
//	OSType			theIconCreator = 'DACi';
//	OSType			theIconType = 'Crsl';
	
	if( theType == 0 ) goto BAIL;
	
	outResult = GetIconRef( kOnSystemDisk, kDACALCreatorType, theType, &theOutputIcon );
	if( outResult != 0 ) outResult = GetIconRef( kOnSystemDisk, kSystemIconsCreator, theType, &theOutputIcon );

	if( theOutputIcon != NULL ) theOutputImage = [[NSImage alloc]initWithIconRef:theOutputIcon];
	if( theOutputImage != NULL ) {
		[theOutputImage setScalesWhenResized:YES];
		[theOutputImage setSize:NSMakeSize( 16.0, 16.0 )];
	}

BAIL:
	return( theOutputImage );
}



#define KEY_GROUPNAME	@"Group"
#define KEY_ENTRIES	@"Entries"

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
		itemDevice = (DACALDeviceRef)NULL;
		itemSlot = 0;
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
		itemDevice = (DACALDeviceRef)NULL;
		itemSlot = 0;
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

- (NSComparisonResult)compare:(id)other {
    // We want the data to be sorted by name, so we compare [self name] to [other name]
    if ([other isKindOfClass:[SimpleNodeData class]]) {
        SimpleNodeData *_other = (SimpleNodeData *)other;
        return [name compare:[_other name]];
    } else {
        return NSOrderedAscending;
    }
}

- (void)setLocation:(NSURL *)loc {
    if (!location || ![location isEqual:loc]) {
	[location release];
	location = [loc retain];
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

@end

@implementation SimpleTreeNode

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

- (id)initFromLocation:(NSURL*)loc {
    // This is a convenience init method to return a tree root of a tree derived from an input dictionary.
    // The input dictionary for this example app is InitInfo.dict.  Look at that file to understand the format.
    SimpleNodeData *data = [SimpleNodeData nodeDataWithURL:loc];
	
	CFDictionaryRef		dataDict = NULL;
	CFArrayRef			dataProps = CFArrayCreate(NULL, (const void**)&kCFURLFileDirectoryContents, 1, &kCFTypeArrayCallBacks);
	CFArrayRef			folderList = NULL;
	Boolean				wasFound = FALSE;
	Boolean				isSlot = CFURLIsSlot( (CFURLRef)loc );
	
	wasFound = CFURLCreateDataAndPropertiesFromResource(NULL, (CFURLRef)loc, NULL, &dataDict, dataProps, NULL);
	if( wasFound ) {
		folderList = (CFArrayRef)CFDictionaryGetValue( dataDict, kCFURLFileDirectoryContents );
		if( folderList == NULL ) CFShow(CFSTR("No Folder List!"));
		else {
			// CFShow( folderList );
			CFRetain( folderList );
		}
		CFRelease( dataDict );
	}

	if( isSlot ) {
		if( CFArrayGetCount(folderList) > 0 ) {
			data = [SimpleNodeData nodeDataWithURL:(NSURL*)CFArrayGetValueAtIndex(folderList, (CFArrayGetCount(folderList)-1))];
			CFRelease( folderList );
			wasFound = CFURLCreateDataAndPropertiesFromResource(NULL, (CFURLRef)loc, NULL, &dataDict, dataProps, NULL);
			if( wasFound ) {
				folderList = (CFArrayRef)CFDictionaryGetValue( dataDict, kCFURLFileDirectoryContents );
				if( folderList == NULL ) CFShow(CFSTR("No Folder List!"));
				else {
					// CFShow( folderList );
					CFRetain( folderList );
				}
				CFRelease( dataDict );
			}
		}
	}
	
    NSEnumerator *entryEnum = [(NSArray*)folderList objectEnumerator];
    id entry;
    SimpleTreeNode *child = nil;
    
    self = [super initWithData:data parent:nil children:[NSArray array]];
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
    
    return self;
}



+ (id)treeFromDictionary:(NSDictionary *)dict {
    return [[[SimpleTreeNode alloc] initFromDictionary:dict] autorelease];
}

+ (id)treeFromLocation:(NSURL *)loc {
    return [[[SimpleTreeNode alloc] initFromLocation:loc] autorelease];
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

@end

