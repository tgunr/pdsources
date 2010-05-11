//
//  MediaDevice.m
//  DACALTester
//
//  Created by Dave Carlton on 3/2/10.
//  Copyright 2010 PolyMicro Systems. All rights reserved.
//

#import "MediaDevice.h"


@implementation MediaDevice

@synthesize vendorName;
@synthesize productName;
@synthesize physicalInterconnect;
@synthesize productRevisionLevel;
@synthesize GUID;
@synthesize CDFeatures;
@synthesize DVDFeatures;
@synthesize image;

+(MediaDevice *) newdevice;
{
	return [[self alloc] init];
}

-(NSImage *) theDeviceType
{

}

-(NSImage *) physicalInterconnectBadge
{
	
}

@end
