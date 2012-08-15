//
//  JSTestService.m
//  PickADisk
//
//  Copyright 2008 PolyMicro Systems. All rights reserved.
//

#import "JSTestService.h"


@implementation JSTestService

-(id)initializeService
{ 
	NSLog(@"JSTestService Init!");
	
	return self;
}

-(void)openService
{
	NSLog(@"JSTestService Open!");
}

-(void)closeService
{
	NSLog(@"JSTestService Close!");
}

@end
