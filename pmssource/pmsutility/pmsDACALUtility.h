/*
 *  pmsDACALUtility.h
 *  PickADisc
 *
 *  Created by Jack Small on 7/16/08.
 *  Copyright 2008 __MyCompanyName__. All rights reserved.
 *
 */

#import <Cocoa/Cocoa.h>
#import <CoreFoundation/CoreFoundation.h>
#import "../carlib/dacallib.h"

OSStatus		DACALRegisterIconResource( CFStringRef theIconFile, OSType theIconType );
NSImage*		DACALGetIconImageForType( int	theType );
IconRef			DACALGetIconRefForType( int	theType );
NSImage*		DACALCreateImageRefForFlavor( NSString* flavorName );


Boolean			CFURLIsCarousel( CFURLRef url );
Boolean			CFURLIsSlot( CFURLRef url );
Boolean			CFURLIsTopInSlot( CFAllocatorRef inAllocator, CFURLRef url );
DACALDeviceRef	CFURLCopyCarouselUUID(  CFAllocatorRef inAllocator, CFURLRef url );
DACALSlotNum	CFURLGetSlotNumber( CFURLRef url, Boolean onlySlotFolders );
IconRef			CFURLGetIcon( CFAllocatorRef allocator, CFURLRef url, OSStatus* outError );
NSImage*		CFURLGetIconAsNSImage( CFAllocatorRef allocator, CFURLRef url, OSStatus* outError );

Boolean			CFURLIsVisible( CFURLRef url );
CFStringRef		CFURLCopyDisplayName( CFAllocatorRef allocator, CFURLRef url, OSStatus* outError );
CFDateRef		CFURLCopyDateSlotAdded( CFAllocatorRef inAllocator, CFURLRef url, SInt32* outError );
CFStringRef		CFURLCopyItemFlavor( CFURLRef url, OSStatus* outError );
OSStatus		CFURLSetItemFlavor( CFURLRef url, CFStringRef newFlavor );

