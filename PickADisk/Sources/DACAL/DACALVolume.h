//
//  DACALVolume.h
//  PickADisk
//
//  Created by Jack Small on 9/9/08.
//  Copyright 2008 PolyMicro Systems. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "dacallib.h"
#import "Volume.h"

@class DACALSlot;
@class DACALDevice;

@interface DACALVolume : Volume {
	NSString     * padIdentifier;
	NSString     * padKnownHost;
	BOOL           padKnownVolume;
	DACALSlot    * padKnownSlot;
	DACALDeviceRef padKnownDevice;
	NSString     * padFlavorGuess;
}

-(NSString *)padIdentifier;
-(NSString *)padKnownHost;

-(BOOL)padKnownVolume;

-(DACALSlot *)padKnownSlot;
-(void)setPadKnownSlot: (DACALSlot *) newSlot;

-(DACALDeviceRef)padKnownDevice;
-(void)setPadKnownDevice: (DACALDeviceRef) newDevice;

-(NSString *)padFlavorGuess;
-(void)setPadFlavorGuess: (NSString *) guessFlavor;

-(BOOL)isIdentifiedAs: (NSString *) testID;
-(BOOL)isIndexable;

-(NSString *)guessPADFlavor;

-(DACALVolume *)initForMountURL: (NSURL *) mountURL;
+(DACALVolume *)volumeForMountURL: (NSURL *) mountURL;

@end        //	DACALVolume