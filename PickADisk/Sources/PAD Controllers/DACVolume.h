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
#import "JSServiceManager.h"

@class DACALSlot;
@class DACALDevice;

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
	NSString*			padKnownHost;
	BOOL				padKnownVolume;	
	DACALSlot*			padKnownSlot;
	
	NSString*			padFlavorGuess;
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
-(NSString*)padKnownHost;

-(BOOL)padKnownVolume;
-(DACALSlot*)padKnownSlot;
-(void)setPadKnownSlot:(DACALSlot*)newSlot;

-(NSString*)padFlavorGuess;
-(void)setPadFlavorGuess:(NSString*)guessFlavor;

-(NSArray*)topLevelDirectory;
-(BOOL)isVolumeURL:(NSURL*)otherURL;
-(BOOL)isIdentifiedAs:(NSString*)testID;
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

@interface DACVolumeService : JSServiceAbstract
{
	CFArrayRef			kextBundles;
	NSMutableArray*		knownVolumes;
	
	NSMutableArray*		pendingMounts;
	NSMutableArray*		pendingUnmounts;
}	

-(CFArrayRef)kextBundles;
-(void)lazyInitKextBundles;

-(NSMutableArray*)pendingMounts;
-(void)setPendingMounts:(NSMutableArray*)newMounts;
-(void)addPendingMount:(NSString*)knownDACDiskID;
-(void)removePendingMount:(NSString*)foundDACDiskID;
-(BOOL)isPendingMount:(NSString*)aDACDiscID;

-(NSMutableArray*)pendingUnmounts;
-(void)setPendingUnmounts:(NSMutableArray*)newUnmounts;
-(void)addPendingUnmount:(NSString*)knownDACDiskID;
-(void)removePendingUnmount:(NSString*)foundDACDiskID;
-(BOOL)isPendingUnmount:(NSString*)aDACDiscID;

-(NSMutableArray*)knownVolumes;
-(DACVolume*)knownVolumeWithURL:(NSURL*)theURL;
-(DACVolume*)knownVolumeWithPath:(NSString*)thePath;
-(NSArray*)knownIndexableVolumes:(NSArray*)testVolumeList;
-(NSArray*)knownSlotVolumes:(NSArray*)testVolumeList;

-(void)newMediaDetected:(NSArray*)newMounts;
-(void)scanMountedRemovableMedia;
-(void)existingMediaRemoved:(NSString*)oldMediaPath;

-(void)carouselDeviceAttached:(DACALDevice*)aDevice;
-(void)carouselDeviceSlotAttached:(DACALSlot*)aSlot;
-(void)carouselDeviceDetached:(DACALDevice*)aDevice;

+(id)sharedVolumeService;

@end

