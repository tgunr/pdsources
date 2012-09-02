//
//  PADLifecycleController.h
//  PickADisk
//
//  Copyright 2008 PolyMicro Systems. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "JSServiceManager.h"

#if PADBOX_EXPIRE_CHECK == 0
	#define		PADBOX_VALID_BEGIN
	#define		PADBOX_VALID_END
	#define		PADBOX_VALIDATED		(TRUE)
	#define		PADBOX_VALIDATED_BOOL	(YES)
#else
	extern BOOL		gPADBOX_EXPIRED;

	#define		PADBOX_VALID_BEGIN		if( gPADBOX_EXPIRED == NO ) {
	#define		PADBOX_VALID_END		}
	#define		PADBOX_VALIDATED		(gPADBOX_EXPIRED == NO)
	#define		PADBOX_VALIDATED_BOOL	(gPADBOX_EXPIRED)


	#define		PADBOX_DELAY	86400.0

	#define		PADBOX_PRIMARY_MESSAGE		CFSTR("PickADisk has expired.")
	#define		PADBOX_SECONDARY_MESSAGE	CFSTR("This version of PickADisk will no longer function.  Try using the “Check For Update” button below to get a newer version or contact ployMicro Systems for instructions.")

	@interface PADBOXController : JSServiceAbstract {

		CFAbsoluteTime		boxToken;
		BOOL				foundUpdate;
		
	}

	-(id)initBOXWithToken:(NSNumber*)token;

	@end

#endif