//
//  DACDriverInstaller.h
//  PickADisk
//
//  Copyright 2008 PolyMicro Systems. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface DACDriverInstaller : NSObject {

}

-(IBAction)installKextAction:(id)sender;
-(IBAction)uninstallKextAction:(id)sender;

+(DACDriverInstaller*)sharedDACInstaller;

+(OSStatus)installDACALDriverKext;
+(OSStatus)uninstallDACALDriverKext;

+(BOOL)isDriverKextInstalled;

+(NSString*)versionOfDriverKextLoaded;
+(NSDate*)dateDriverKextInstalled;

@end
