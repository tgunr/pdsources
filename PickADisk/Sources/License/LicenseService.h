//
//  LicenseService.h
//  PickADisk
//
//  Created by Jack Small on 10/30/08.
//  Copyright 2008 Jack Small. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "AquaticPrime.h"

extern NSString*		kPADLicenseDataPrefKey;
extern NSString*		kPADLicenseFirstRunPrefKey;

extern NSString*		kPADLicenseDictKeyUserName;
extern NSString*		kPADLicenseDictKeyUserEmail;	
extern NSString*		kPADLicenseDictKeyComment;
extern NSString*		kPADLicenseDictKeyInvoiceNum;


@interface PADLicense : NSObject
{
	NSDictionary*		licenseDict;
	NSData*				licenseData;
	BOOL				isLicenseValid;
}

- (NSDictionary*)licenseDict;
- (void)setLicenseDict:(NSDictionary*)newDict;
- (BOOL)changeLicenseDict:(NSDictionary*)newDict;

- (NSData*)licenseData;
- (void)setLicenseData:(NSData*)newData;

- (BOOL)isLicenseValid;

- (BOOL)saveAsPreference:(NSString*)theKey;

- (id)objectForLicenseKey:(NSString*)keyName;

- (id)initFromLicenseData:(NSData*)newLicenseData;
+ (id)licenseFromPrefsKey:(NSString*)theKey;
+ (id)licenseFromFile:(NSString*)licensePath;

@end	//	PADLicense

typedef	PADLicense*		PADLicenseRef;

@interface PADLicenseService : NSObject {

	AquaticPrime*		licenseValidator;
	NSMutableString*	licenseKey;
	PADLicenseRef		licenseProof;
	
	BOOL				licenseCracked;
}

+ (id)sharedLicenseService;
- (id)init;

- (AquaticPrime*)licenseValidator;
- (void)setLicenseValidator:(AquaticPrime*)newValidator;

- (PADLicenseRef)licenseProof;
- (void)setLicenseProof:(PADLicenseRef)newLicense;
- (BOOL)changeLicenseProof:(PADLicenseRef)newLicense saveAsKey:(NSString*)prefKey;

- (BOOL)licenseValid;
- (BOOL)licenseExists;
- (BOOL)licenseCracked;
- (NSInteger)licenseLimit;

- (void)reportCrackWithReason:(NSString*)howCracked;
- (BOOL)registerLicenseFromFile:(NSString*)licensePath;
- (BOOL)registerLicenseFromFileURL:(NSURL*)licenseURL;

- (id)objectForLicenseKey:(NSString*)keyName;
- (NSString*)stringForLicenseKey:(NSString*)keyName;
- (NSNumber*)numberForLicenseKey:(NSString*)keyName;
- (NSDate*)dateForLicenseKey:(NSString*)keyName;

@end	//	PADLicenseService

typedef PADLicenseService*	PADLicenseServiceRef;


