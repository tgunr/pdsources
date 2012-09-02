//
//  DACALIndexState.h
//  PickADisk
//
//  Created by Dave Carlton on 06/24/11.
//  Copyright 2011 Polymicro Systems. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface DACALIndexState : NSObject
{
	NSMutableDictionary*	savedViewData;
}

-(void)restoreSettings;
-(void)removeSetting:(NSString*)settingName forKey:(NSString*)keyName;
-(void)addSettingsForKey:(NSString*)keyName saveView:(NSOutlineView*)doView saveSelection:(BOOL)doSelect saveSorts:(BOOL)doSorts;
+(id)saveSetupForKey:(NSString*)keyName saveView:(NSOutlineView*)doView saveSelection:(BOOL)doSelect saveSorts:(BOOL)doSorts;

@end

