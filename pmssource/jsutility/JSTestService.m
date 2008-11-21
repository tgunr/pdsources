//
//  JSTestService.m
//  PickADisk
//
//  Created by Jack Small on 11/6/08.
//  Copyright 2008 Jack Small. All rights reserved.
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
