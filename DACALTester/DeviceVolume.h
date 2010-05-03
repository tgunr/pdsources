//
//  DeviceVolume.h
//  DACALTester
//
//  Created by Dave Carlton on 01/19/10.
//  Copyright 2010 PolyMicro Systems. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <DiskArbitration/DiskArbitration.h>
#import <IOKit/IOKitLib.h>
#import <IOKit/scsi/SCSITaskLib.h>
#import "dacallib.h"

@interface DeviceVolume : NSObject {
	FSVolumeRefNum		mountVolume;
	NSURL*				volumeURL;
	DADiskRef			volumeDiskRef;
	
	NSString*			mediaTitle;
	NSString*			mediaType;
	NSNumber*			mediaSize;
	IconRef				mediaIcon;
	CFUUIDRef			mediaUUID;
}

-(FSVolumeRefNum)mountVolume;
-(NSURL*)volumeURL;
-(NSString*)volumePath;
-(DADiskRef)volumeDiskRef;

-(NSString*)mediaTitle;
-(NSString*)mediaType;
-(NSNumber*)mediaSize;
-(IconRef)mediaIcon;
-(CFUUIDRef)mediaUUID;

-(BOOL)padKnownVolume;

-(NSArray*)topLevelDirectory;
-(BOOL)isVolumeURL:(NSURL*)otherURL;

-(NSMutableDictionary*)getDVDMediaInfo;
-(BOOL)ejectVolume;

- (void) readDVDStructure:(MMCDeviceInterface**)mmcInterface
			   withFormat:(SCSICmdField1Byte)format
				  address:(SCSICmdField4Byte)address
					layer:(SCSICmdField1Byte)layer
		   intoDictionary:(NSMutableDictionary*)dict;

-(DeviceVolume*)initForMountURL:(NSURL*)mountURL;
+(DeviceVolume*)volumeForMountURL:(NSURL*)mountURL;
+(NSArray*)detectedMounts:(NSArray*)newMounts;

@end // DeviceVolume

@interface DACALDeviceVolume : DeviceVolume {
	DACALDeviceRef		dacalKnownDevice;

}
@property (assign) DACALDeviceRef dacalKnownDevice;

@end