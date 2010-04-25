//
//  dacalstrings.h
//  PickADisk
//
//  Created by Dave Carlton on 07/25/09.
//  Copyright 2009 PolyMicro Systems. All rights reserved.
//

#import <Cocoa/Cocoa.h>

//	Slot reservation dictionary keys
extern	NSString*	kDACSlotReservationKeyTime;
extern  NSString*	kDACSlotReservationKeyType;
extern	NSString*	kDACSlotReservationKeyUser;
extern	NSString*	kDACSlotReservationKeyHost;
extern	NSString*	kDACSlotReservationKeyCountCheckOut;

extern	NSString*	kDACSlotReservationTypeCheckOut;
extern	NSString*	kDACSlotReservationTypeCheckIn;

extern	NSString*	kDACBookmarkLocationInSidebar;
extern	NSString*	kDACBookmarkLocationInMenubar;
extern	NSString*	kDACBookmarkLocationInBookmarks;

//	Discovery Keys
extern	NSString*	kDACDiscKeyCheckIn;
extern	NSString*	kDACDiscKeyCheckOut;
extern	NSString*	kDACDiscKeyRecognized;
extern	NSString*	kDACDiscKeyUnrecognized;

//	Discovery Values
extern	NSInteger	kDACDVCheckInOpenToSlot;
extern	NSInteger	kDACDVCheckInDisplayDetails;				//	Display Not Implemented
extern	NSInteger	kDACDVCheckInOpenAndDisplay;				//	Display Not Implemented
extern	NSInteger	kDACDVCheckInDoNothing;
extern	NSInteger	kDACDVCheckOutAutoMatch;
extern	NSInteger	kDACDVCheckOutCloseDoor;
extern	NSInteger	kDACDVCheckOutMatchAndCloseDoor;
extern	NSInteger	kDACDVCheckOutDoNothing;
extern	NSInteger	kDACDVKnownIDAutoCheckIn;
extern	NSInteger	kDACDVKnownIDDoNothing;
extern	NSInteger	kDACDVUnknownIDDisplayAddWindow;
extern	NSInteger	kDACDVUnknownIDAutoAssignToNextSlot;		//	Auto Index Not Implemented
extern	NSInteger	kDACDVUnknownIDBeginBatchMode;				//	Batch Mode Not Implemented
extern	NSInteger	kDACDVUnknownIDDoNothing;

//	Slot File Names
extern NSString*	kDACSlotReservationFileName;
extern NSString*	kDACSlotReservationFileNameWithExtension;
extern NSString*	kDACSlotIconFileNameWithExtension;

