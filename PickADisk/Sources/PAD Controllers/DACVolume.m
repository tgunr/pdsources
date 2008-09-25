//
//  DACVolume.m
//  PickADisk
//
//  Created by Jack Small on 9/9/08.
//  Copyright 2008 Jack Small. All rights reserved.
//

#import "DACVolume.h"


@implementation DACVolume

-(void)dealloc
{
	if( volumeDiskRef ) CFRelease( volumeDiskRef );
	
	volumeDiskRef = nil;
	
	[super dealloc];
}

-(FSVolumeRefNum)mountVolume
	{ return mountVolume; }

-(NSURL*)volumeURL
	{ return volumeURL; }

-(DADiskRef)volumeDiskRef
	{ return volumeDiskRef; }

-(DACVolume*)initForMountURL:(NSURL*)mountURL
{
	if( self = [super init] )
	{
		FSRef			theRef;
		FSCatalogInfo	theInfo;
		OSStatus		theErr;
		CFDictionaryRef	volumeData = NULL;
		
		theErr = !CFURLGetFSRef((CFURLRef)mountURL, &theRef );
		if( theErr != 0 ) goto FAILED;

		theErr = FSGetCatalogInfo( &theRef, kFSCatInfoVolume, &theInfo, NULL, NULL, NULL );
		if( theErr != 0 ) goto FAILED;
		mountVolume = theInfo.volume;
		
		theErr = FSCopyDADiskForVolume( mountVolume, &volumeDiskRef );
		if( theErr != 0 ) goto FAILED;
		
		volumeData = DADiskCopyDescription( volumeDiskRef );
		if( volumeData == NULL ) goto FAILED;
		
		CFShow( volumeData );
		
		CFRelease( volumeData );
		
		
	}
	return self;
	
FAILED:
	return nil;
}

+(DACVolume*)volumeForMountURL:(NSURL*)mountURL
	{ return [[DACVolume alloc] initForMountURL:mountURL]; }
						   
+(NSArray*)detectedMounts:(NSArray*)newMounts
{
	NSArray*			outMounts = nil;
	int					newIndex, newCount = [newMounts count];
	NSMutableArray*		newList = [[NSMutableArray alloc] initWithCapacity:newCount];
	NSURL*				newItemURL;
	DACVolume*			newVolume = nil;
	
	//if( (newList == nil) || (newCount == 0) ) return outMounts;
	
	for( newIndex=0; newIndex < newCount; newIndex++ )
	{
		newItemURL = (NSURL*)[newMounts objectAtIndex:newIndex];
		newVolume = [DACVolume volumeForMountURL:newItemURL];
		if( newVolume ) [newList addObject:newVolume];
	}
	
	if( [newList count] > 0 )
		outMounts = [NSArray arrayWithArray:newList];
	
	[newList release];
	
	return outMounts;
}

@end
