#ifdef __OBJC__
    #import <Foundation/Foundation.h>
    #import <AppKit/AppKit.h>
	#import "pms.h"
	#import "dacallib.h"
	
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
	
#endif
