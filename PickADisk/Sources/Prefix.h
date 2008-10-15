/*
 *  Prefix.h
 *  PickADisc
 *
 *  Created by Dave Carlton on 05/20/08.
 *  Copyright 2008 Polymicro Systems. All rights reserved.
 *
 */

//#define __DCDEBUG												// define this to get debug output in the driver specifically.

#ifdef __OBJC__
    #import <Foundation/Foundation.h>
    #import <AppKit/AppKit.h>
	#import "pms.h"
	#import "DACALDeviceObjC.h"
	#import "NSApplication_Extensions.h"
	#import "NSData_Extensions.h"
	#import "NSString_Extensions.h"
	#import "NSSlider_Animation.h"
	#import "AppController.h"
	#import "PADLifecycleSetup.h"
	
	#if MAC_OS_X_VERSION_MIN_REQUIRED < MAC_OS_X_VERSION_10_5
		typedef float CGFloat;
		enum {
			// An empty area, or did not hit in the cell
			NSCellHitNone = 0,
			// A content area in the cell
			NSCellHitContentArea = 1 << 0,
			// An editable text area of the cell
			NSCellHitEditableTextArea = 1 << 1,
			// A trackable area in the cell
			NSCellHitTrackableArea = 1 << 2,
		};

		#if __LP64__
			typedef long NSInteger;
			typedef unsigned long NSUInteger;
	
		#else
			typedef int NSInteger;
			typedef unsigned int NSUInteger;
		#endif
	#endif

	// System sound ids
	#define kASSystemSoundDoink		1
	#define kASSystemSoundShred		13
	#define kASSystemSoundPoof		15
	#define kASSystemSoundTrash		16
	#define kASSystemSoundSuccess	22

#endif
