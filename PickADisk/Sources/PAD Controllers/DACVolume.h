//
//  DACVolume.h
//  PickADisk
//
//  Created by Jack Small on 9/9/08.
//  Copyright 2008 Jack Small. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <DiskArbitration/DiskArbitration.h>

@interface DACVolume : NSObject {

	FSVolumeRefNum		mountVolume;
	NSURL*				volumeURL;
	DADiskRef			volumeDiskRef;
	
}

-(FSVolumeRefNum)mountVolume;
-(NSURL*)volumeURL;
-(DADiskRef)volumeDiskRef;

-(DACVolume*)initForMountURL:(NSURL*)mountURL;
+(DACVolume*)volumeForMountURL:(NSURL*)mountURL;
+(NSArray*)detectedMounts:(NSArray*)newMounts;

@end
