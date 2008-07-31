//
//  PADCarouselOperation.h
//  PickADisc
//
//  Created by Jack Small on 7/29/08.
//  Copyright 2008 Jack Small. All rights reserved.
//

#import <Cocoa/Cocoa.h>

enum PADCarOps {
	kPADOpIndexingComplete,
	kPADOpOpenSlot,
	kPADOpSearch,
};

@interface PADCarouselOperation : NSOperation {

	int					opType;
	NSURL*				volURL;
	DACALDeviceRef		targetDevice;
	DACALSlotNum		targetSlot;
	NSString*			targetString1;
	NSString*			targetString2;
	NSArray*			targetArray;
	
	id					finishTarget;
}

+startSeachInLocations:(NSArray*) inLocs forTerm:(NSString*)inTerm withOptions:(NSString*)inOptions;

@end
