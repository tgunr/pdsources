//
//  MediaDevice.h
//  DACALTester
//
//  Created by Dave Carlton on 3/2/10.
//  Copyright 2010 PolyMicro Systems. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface MediaDevice : NSObject {
	NSString * vendorName;
	NSString * productName;
	NSString * physicalInterconnect;
	NSString * productRevisionLevel;
	NSData   * GUID;
	
	UInt32    CDFeatures;
	UInt32    DVDFeatures;
	NSImage * image;
}

@property (assign) NSString * vendorName;
@property (assign) NSString * productName;
@property (assign) NSString * physicalInterconnect;
@property (assign) NSString * productRevisionLevel;
@property (assign) NSData   * GUID;
@property (assign) UInt32     CDFeatures;
@property (assign) UInt32     DVDFeatures;
@property (assign) NSImage  * image;

+(MediaDevice *) newdevice;
-(NSImage *) theDeviceType;
-(NSImage *) physicalInterconnectBadge;
@end