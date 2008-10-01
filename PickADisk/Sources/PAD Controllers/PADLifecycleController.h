//
//  PADLifecycleController.h
//  PickADisk
//
//  Created by Jack Small on 8/2/08.
//  Copyright 2008 Jack Small. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#if PADBOX_EXPIRE_CHECK == 0
	#define		PADBOX_VALID_BEGIN
	#define		PADBOX_VALID_END
	#define		PADBOX_VALIDATED		(TRUE)
	#define		PADBOX_VALIDATED_BOOL	(YES)
#else
	extern BOOL		gPADBOX_EXPIRED;

	#define		PADBOX_VALID_BEGIN		if( gPADBOX_EXPIRED == YES ) goto PADBOXBUMMER;
	#define		PADBOX_VALID_END		PADBOXBUMMER:
	#define		PADBOX_VALIDATED		(gPADBOX_EXPIRED == NO)
	#define		PADBOX_VALIDATED_BOOL	(gPADBOX_EXPIRED)


	#define		PADBOX_DELAY	86400.0

	#define		PADBOX_PRIMARY_MESSAGE		CFSTR("PickADisk has expired.")
	#define		PADBOX_SECONDARY_MESSAGE	CFSTR("This version of PickADisk will no longer function.  Try using software update under the 'File' menu to get a newer version or contact ployMicro Systems for instructions.")

	@interface PADBOXController : NSObject {

		CFAbsoluteTime		boxToken;
		BOOL				foundUpdate;
		
	}

	+(id)startBOXWithToken:(NSNumber*)token;

	@end

#endif