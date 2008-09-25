//
//  DACDriverInstaller.h
//  PickADisk
//
//  Created by Jack Small on 9/7/08.
//  Copyright 2008 Jack Small. All rights reserved.
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
