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

-(NSArray*)topLevelDirectory;
-(BOOL)isVolumeURL:(NSURL*)otherURL;
-(BOOL)isIndexable;
-(BOOL)isCD;
-(BOOL)isDVD;
-(BOOL)isBD;
-(NSString*)guessPADFlavor;
-(BOOL)ejectVolume;

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

-(DACVolume*)knownVolumeWithURL:(NSURL*)theURL;
-(DACVolume*)knownVolumeWithPath:(NSString*)thePath;
-(NSArray*)knownIndexableVolumes:(NSArray*)testVolumeList;

+(id)sharedVolumeService;

@end

