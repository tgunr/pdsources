//
//  PADPrefsTreeController.h
//  PickADisk
//
//  Created by Jack Small on 10/14/08.
//  Copyright 2008 Jack Small. All rights reserved.
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
