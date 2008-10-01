//
//  LicenseController.h
//  PickADisk
//
//  Created by Dave Carlton on 09/30/08.
//  Copyright 2008 Polymicro Systems. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PADPrefsController.h"
#import "AquaticPrime.h"

@interface PADPrefsController(LicenseExtension)

- (IBAction)selectLicenseFile:(id)sender;
- (IBAction)submitLicense:(id)sender;

- (void)pathControlDoubleClick:(id)sender;

@end

@interface LicenseController : NSObject
{
	NSDictionary *			licenseDict;
	AquaticPrime *			licenseValidator;
}

+ (id)shared;
- (id)init;
- (AquaticPrime *)licenseValidator;
- (NSDictionary *)licenseDict;
- (NSDictionary*)checkLicense:(NSString*)licensePath;
- (BOOL) fileValid:(NSString*)licensePath ;
- (BOOL) dataValid;
@end

