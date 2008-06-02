//
//  MediaDiscMO.m
//  PMTB
//
//  Created by Dave Carlton on 05/20/08.
//  Copyright 2008 Polymicro Systems. All rights reserved.
//

#import "MediaDiscMO.h"


@implementation MediaDiscMO

- (void)awakeFromInsert {
	[self setValue:[NSDate date] forKey: @"dateAdded"];
	CFUUIDRef mediaDiscUUID = CFUUIDCreate(kCFAllocatorDefault);
	CFStringRef mediaDiscUUIDString = CFUUIDCreateString(kCFAllocatorDefault, mediaDiscUUID);
	[self setValue:mediaDiscUUIDString forKey:@"UUID"];
}

@end
