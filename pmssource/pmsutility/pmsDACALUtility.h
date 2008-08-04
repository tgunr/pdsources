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

Boolean			CFURLIsCarousel( CFURLRef url );
Boolean			CFURLIsSlot( CFURLRef url );
DACALDeviceRef	CFURLCopyCarouselUUID( CFURLRef url );
DACALSlotNum	CFURLGetSlotNumber( CFURLRef url, Boolean onlySlotFolders );
IconRef			CFURLGetIcon( CFAllocatorRef allocator, CFURLRef url, OSStatus* outError );
NSImage*		CFURLGetIconAsNSImage( CFAllocatorRef allocator, CFURLRef url, OSStatus* outError );

Boolean			CFURLIsVisible( CFURLRef url );
CFStringRef		CFURLCopyDisplayName( CFAllocatorRef allocator, CFURLRef url, OSStatus* outError );

