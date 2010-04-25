//
//  dacalstrings.m
//  PickADisk
//
//  Created by Dave Carlton on 07/25/09.
//  Copyright 2009 PolyMicro Systems. All rights reserved.
//

#import "dacalconstants.h"


//	Externally referenced

NSString*	kDACSlotReservationKeyTime			= @"DACResTime";
NSString*	kDACSlotReservationKeyType			= @"DACResType";
NSString*	kDACSlotReservationKeyUser			= @"DACResUser";
NSString*	kDACSlotReservationKeyHost			= @"DACResHost";
NSString*	kDACSlotReservationKeyCountCheckOut	= @"DACResCheckOutCount";

NSString*	kDACSlotReservationTypeCheckOut		= @"DACCheckOut";
NSString*	kDACSlotReservationTypeCheckIn		= @"DACCheckIn";

NSString*	kDACBookmarkLocationInSidebar		= @"_DACSide";
NSString*	kDACBookmarkLocationInMenubar		= @"_DACMenu";
NSString*	kDACBookmarkLocationInBookmarks		= @"_DACBook";

//	Discovery Keys

NSString*	kDACDiscKeyCheckIn					= @"PADCheckInEject";
NSString*	kDACDiscKeyCheckOut					= @"PADCheckOutMount";
NSString*	kDACDiscKeyRecognized				= @"PADKnownDiscEject";
NSString*	kDACDiscKeyUnrecognized				= @"PADNewDiscMounted";

//	Discovery Values

NSInteger	kDACDVCheckInOpenToSlot				= 0;
NSInteger	kDACDVCheckInDisplayDetails			= 1;
NSInteger	kDACDVCheckInOpenAndDisplay			= 2;
NSInteger	kDACDVCheckInDoNothing				= 4;

NSInteger	kDACDVCheckOutAutoMatch				= 0;
NSInteger	kDACDVCheckOutCloseDoor				= 1;
NSInteger	kDACDVCheckOutMatchAndCloseDoor		= 2;
NSInteger	kDACDVCheckOutDoNothing				= 4;

NSInteger	kDACDVKnownIDAutoCheckIn			= 0;
NSInteger	kDACDVKnownIDDoNothing				= 2;

NSInteger	kDACDVUnknownIDDisplayAddWindow		= 0;
NSInteger	kDACDVUnknownIDAutoAssignToNextSlot	= 1;
NSInteger	kDACDVUnknownIDBeginBatchMode		= 2;
NSInteger	kDACDVUnknownIDDoNothing			= 4;

//	Slot Files

NSString*	kDACSlotReservationFileName					= @".reservations";
NSString*	kDACSlotReservationFileNameWithExtension	= @".reservations.plist";
NSString*	kDACSlotIconFileNameWithExtension			= @".DACDiscIcon.icns";

