//
//  NSApplication_Extensions.m
//  PickADisc
//
//  Created by Jack Small on 7/14/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "NSApplication_Extensions.h"

/*
@implementation NSApplication(MyExtensions)

- (id)addVolumeController { return addVolumeController; }
- (void)setAddVolumeController:(id)inAVC
{
	addVolumeController = [inAVC retain];
//    if (!addVolumeController || ![addVolumeController isEqual:inAVC]) {
//		[addVolumeController release];
//		addVolumeController = [inAVC retain];
//    }
}
@end
*/
@implementation NSDate(MyExtensions)

+(NSDate*)tomorrow
{ return [[NSDate date] addTimeInterval:86400.0]; }

+(NSDate*)yesterday
	{ return [[NSDate date] addTimeInterval:-86400.0]; }

-(BOOL)isBetweenStartDate:(NSDate*)startDate andEndDate:(NSDate*)endDate
{
	BOOL	isBetween = NO;
	
	NSDate*	lowDate = startDate;
	NSDate*	hiDate = endDate;
	
	if( [lowDate compare:hiDate] != NSOrderedAscending )
	{
		lowDate = endDate;
		endDate = startDate;
	}
	
	if( [self compare:lowDate] != NSOrderedAscending )
		if( [self compare:hiDate] != NSOrderedDescending )
			isBetween = YES;
	
	return isBetween;
}

@end		//NSDate(MyExtensions)