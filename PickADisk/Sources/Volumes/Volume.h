//
//  Volume.h
//  DACALTester
//
//  Created by Dave Carlton on 2/12/10.
//  Copyright 2010 PolyMicro Systems. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <IOKit/scsi/SCSITaskLib.h>


@interface Volume : NSObject {
	FSVolumeRefNum mountVolume;
	NSURL        * volumeURL;
	DADiskRef      volumeDiskRef;
	FSRef			iconFileRef;	
	NSString * mediaTitle;
	NSString * mediaType;
	NSNumber * mediaSize;
	IconRef    mediaIcon;
	CFUUIDRef  mediaUUID;
	NSString*			infoMD5;	
}

-(FSVolumeRefNum)mountVolume;
-(NSURL *)volumeURL;
-(NSString *)volumePath;
-(DADiskRef)volumeDiskRef;

-(NSString *)mediaTitle;
-(NSString *)mediaType;
-(NSNumber *)mediaSize;
-(IconRef)mediaIcon;
-(CFUUIDRef)mediaUUID;

-(NSArray *)topLevelDirectory;
-(BOOL)isVolumeURL: (NSURL *) otherURL;
-(BOOL)isCD;
-(BOOL)isDVD;
-(BOOL)isBD;
-(NSMutableDictionary *)getDVDMediaInfo;
-(BOOL)ejectVolume;

-(void) readDVDStructure: (MMCDeviceInterface * *) mmcInterface
			  withFormat: (SCSICmdField1Byte) format
				 address: (SCSICmdField4Byte) address
				   layer: (SCSICmdField1Byte) layer
		  intoDictionary: (NSMutableDictionary *) dict;
-(Volume *)initForMountURL: (NSURL *) mountURL;
+(NSArray *)detectedMounts: (NSArray *) newMounts;

@end
