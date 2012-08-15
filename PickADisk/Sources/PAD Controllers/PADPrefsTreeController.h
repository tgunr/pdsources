//
//  PADPrefsTreeController.h
//  PickADisk
//
//  Copyright 2008 PolyMicro Systems. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "TreeController.h"

@interface PADPrefsTreeController : TreeControllerDataSource {

	NSMutableDictionary*		itemInfo;
	
}

- (IBAction)restoreTreeIndexPrefs:(id)sender;

+ (id)sharedPrefsTree;

- (NSMutableDictionary*)itemInfo;

@end
