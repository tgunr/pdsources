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

- (IBAction)selectLicenseFileBtn:(id)sender;
- (IBAction)submitLicense:(id)sender;

- (void)pathControlDoubleClick:(id)sender;

@end

@interface LicenseController : NSObject
{
	NSDictionary *			licenseDict;
	AquaticPrime *			licenseValidator;
	NSData *				licenseData;
}

+ (id)shared;
- (id)init;
- (AquaticPrime *)licenseValidator;
- (void)setLicenseValidator:(AquaticPrime *)newValidator;
- (NSDictionary *)licenseDict;
- (void)setLicenseValidator:(AquaticPrime *)newValidator;
- (void)setLicenseData:(NSData *)data;
- (NSDictionary*)checkLicenseFile:(NSString*)licensePath;
- (BOOL) openLicenseFile:(NSString*)licensePath ;
- (BOOL)registerLicenseFromFile:(NSString*)licensePath;
- (BOOL) licenseValid;
@end

