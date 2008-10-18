//
//  DACVolume.h
//  PickADisk
//
//  Created by Jack Small on 9/9/08.
//  Copyright 2008 Jack Small. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <DiskArbitration/DiskArbitration.h>
#import <IOKit/IOKitLib.h>
#import <IOKit/scsi/SCSITaskLib.h>

@class DACALSlot;

@interface DACVolume : NSObject {

	FSVolumeRefNum		mountVolume;
	NSURL*				volumeURL;
	DADiskRef			volumeDiskRef;
		
	NSString*			mediaTitle;
	NSString*			mediaType;
	NSNumber*			mediaSize;
	IconRef				mediaIcon;
	CFUUIDRef			mediaUUID;
	
	NSString*			padIdentifier;
	BOOL				padKnownVolume;	
	DACALSlot*			padKnownSlot;
	NSString*			padKnownHost;
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

-(NSString*)padIdentifier;
-(BOOL)padKnownVolume;
-(DACALSlot*)padKnownSlot;
-(NSString*)padKnownHost;

-(NSArray*)topLevelDirectory;
-(BOOL)isVolumeURL:(NSURL*)otherURL;
-(BOOL)isIndexable;
-(BOOL)isCD;
-(BOOL)isDVD;
-(BOOL)isBD;
-(NSString*)guessPADFlavor;
-(NSDictionary*)getDVDMediaInfo;
-(BOOL)ejectVolume;

- (void) readDVDStructure:(MMCDeviceInterface**)mmcInterface
			   withFormat:(SCSICmdField1Byte)format
				  address:(SCSICmdField4Byte)address
					layer:(SCSICmdField1Byte)layer
		   intoDictionary:(NSMutableDictionary*)dict;

-(DACVolume*)initForMountURL:(NSURL*)mountURL;
+(DACVolume*)volumeForMountURL:(NSURL*)mountURL;
+(NSArray*)detectedMounts:(NSArray*)newMounts;

@end		//	DACVolume

@interface DACVolumeService : NSObject
{
	CFArrayRef			kextBundles;
	NSMutableArray*		knownVolumes;	
}	

-(CFArrayRef)kextBundles;
-(NSMutableArray*)knownVolumes;

-(void)lazyInitKextBundles;

-(DACVolume*)knownVolumeWithURL:(NSURL*)theURL;
-(DACVolume*)knownVolumeWithPath:(NSString*)thePath;
-(NSArray*)knownIndexableVolumes:(NSArray*)testVolumeList;
-(NSArray*)knownSlotVolumes:(NSArray*)testVolumeList;

+(id)sharedVolumeService;

@end

