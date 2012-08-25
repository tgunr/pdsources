//
//  LicenseService.m
//  PickADisk
//
//  Created by Jack Small on 10/30/08.
//  Copyright 2008 Jack Small. All rights reserved.
//

#import "LicenseService.h"

NSString*		kPADLicenseDataPrefKey			=	@"licenseDict";
NSString*		kPADLicenseFirstRunPrefKey		=	@"demoAnnounce";

NSString*		kPADLicenseDictKeyUserName		=	@"Name";
NSString*		kPADLicenseDictKeyUserEmail		=	@"Email";
NSString*		kPADLicenseDictKeyComment		=	@"Note";
NSString*		kPADLicenseDictKeyInvoiceNum	=	@"Invoice";


@implementation PADLicense

- (NSDictionary*)licenseDict
	{ return licenseDict; }

- (void)setLicenseDict:(NSDictionary*)newDict
{
	if( !licenseDict || ![licenseDict isEqual:newDict] )
	{
		if( newDict ) [newDict retain];
		if( licenseDict ) [licenseDict release];
		licenseDict = newDict;
	}	
}

- (BOOL)changeLicenseDict:(NSDictionary*)newDict
{
	BOOL	workedOut = NO;

	[self setLicenseDict:newDict];
	
	isLicenseValid = (newDict != nil);
	workedOut = [[PADLicenseService sharedLicenseService] changeLicenseProof:self saveAsKey:nil];
	isLicenseValid = workedOut;
	
	return workedOut;
}

- (NSData*)licenseData
	{ return licenseData; }

- (void)setLicenseData:(NSData*)newData
{
	if( !licenseData || ![licenseData isEqual:newData] )
	{
		if( newData ) [newData retain];
		if( licenseData ) [licenseData release];
		licenseData = newData;
	}	
}

- (BOOL)isLicenseValid
	{ return isLicenseValid; }

- (BOOL)saveAsPreference:(NSString*)theKey
{
	BOOL	goodSave = NO;
	
	if( (licenseData != nil) && (theKey != nil) )
	{
		[[NSUserDefaults standardUserDefaults] setObject:licenseData forKey:theKey];
		goodSave = [[NSUserDefaults standardUserDefaults] synchronize];
	}
	
	return goodSave;
}

- (id)objectForLicenseKey:(NSString*)keyName
{
	id		dictObj = nil;
	
	if( [self isLicenseValid] )
		dictObj = [[self licenseDict] objectForKey:keyName];
	
	return dictObj;
}

- (id)initFromLicenseData:(NSData*)newLicenseData
{
	NSDictionary*	newLicenseDict = [[[PADLicenseService sharedLicenseService] licenseValidator] dictionaryForLicenseData: newLicenseData];
	id				newSelf = nil;
	BOOL			goodLicense = NO;

	isLicenseValid = NO;
	
	if( newLicenseData && newLicenseDict )
		if( self = [super init] )
		{
			[self setLicenseData:newLicenseData];
			goodLicense = [self changeLicenseDict:newLicenseDict];
			
			if( goodLicense )
				newSelf = self;
		}

	if( newSelf == nil )
		[self autorelease];
	
	return newSelf;
}

- (void)dealloc {
	[licenseDict release];
	[licenseData release];
	[super dealloc];
}

+ (id)licenseFromPrefsKey:(NSString*)theKey
{
	NSData*		newData = [[NSUserDefaults standardUserDefaults] objectForKey:theKey];
	if( newData == nil )
        return nil;
	return [[PADLicense alloc] initFromLicenseData:newData]; 
}

+ (id)licenseFromFile:(NSString*)licensePath
{
	NSData*		newData = [NSData dataWithContentsOfFile:licensePath];
	if( newData == nil )
        return nil;
	return [[PADLicense alloc] initFromLicenseData:newData]; 
}

@end	//	PADLicense


@implementation PADLicenseService

+ (id)sharedLicenseService { return [PADLicenseService sharedService]; }


-(void)initSelf
{	
	//NSLog(@"LicenseService Created");
    
	// This string is specially constructed to prevent key replacement 	// *** Begin Public Key ***
	NSMutableString *key = [NSMutableString string];
	[key appendString:@"0x9F7B984C1758F45A31E162D27B76"];
	[key appendString:@"A2460DE570C1F2C6C51080707FC5C5"];
	[key appendString:@"2D480EDCF54F57B54BA5"];
	[key appendString:@"7"];
	[key appendString:@"7"];
	[key appendString:@"A28908DD"];
	[key appendString:@"ABE26C974C2436053483"];
	[key appendString:@"6"];
	[key appendString:@"6"];
	[key appendString:@"C649C455"];
	[key appendString:@"D10B4EB382C36763A60F8C"];
	[key appendString:@"E"];
	[key appendString:@"E"];
	[key appendString:@"C24AE5"];
	[key appendString:@"4035C4CEA0108B31"];
	[key appendString:@"D"];
	[key appendString:@"D"];
	[key appendString:@"1D9915450B96"];
	[key appendString:@"7B510B07379"];
	[key appendString:@"3"];
	[key appendString:@"3"];
	[key appendString:@"CA428780D997E6DB3"];
	[key appendString:@"94238E65A53919B127A76B9FEB6184"];
	[key appendString:@"11A5B211A3FA6B873F"];
	// *** End Public Key ***

	// Instantiate AquaticPrime
	[self setLicenseValidator: [AquaticPrime aquaticPrimeWithKey:key]];
	
	// Blacklist bad licenses
	[licenseValidator setBlacklist:[NSArray arrayWithObject:@"56237cb06e032ba9d7ed5c4b5f5f89790493386e"]];
}

-(void)openService
{
	PADBOX_VALID_BEGIN

	// init from prefs if possible
	[self changeLicenseProof:[PADLicense licenseFromPrefsKey:kPADLicenseDataPrefKey] saveAsKey:nil];
	
	// Wake up the License Controller which may show modal UI
	// Since we're not requiring the license we can start it here instead of in the init
	[NSBundle loadNibNamed:@"License" owner:[NSApplication sharedApplication]];	
	
	PADBOX_VALID_END
}

- (AquaticPrime*)licenseValidator
	{ return licenseValidator; }

- (void)setLicenseValidator: (AquaticPrime *) newValidator {
	if (!licenseValidator || ![licenseValidator isEqual: newValidator]) {
		if (newValidator)
			[newValidator retain];
		if (licenseValidator)
			[licenseValidator release];
		licenseValidator = newValidator;
	}
}

- (PADLicenseRef)licenseProof
	{ return licenseProof; }

- (void)setLicenseProof: (PADLicenseRef) newLicense {
	if (!licenseProof || ![licenseProof isEqual: newLicense]) {
		if (newLicense)
			[newLicense retain];
		if (licenseProof)
			[licenseProof release];
		licenseProof = newLicense;
	}
}

- (BOOL)changeLicenseProof:(PADLicenseRef)newLicense saveAsKey:(NSString*)prefKey
{
	BOOL	goodLicense = NO;
	
	[self setLicenseProof:newLicense];
	goodLicense = [self licenseValid];
	
	if( goodLicense && prefKey )
		[newLicense saveAsPreference:prefKey];
	
	return goodLicense;
}

- (BOOL)licenseValid
{
	BOOL	goodLicense = NO;
	
	if( licenseProof )
		goodLicense = [licenseProof isLicenseValid];
	
	return goodLicense; 
}

- (BOOL)licenseExists
	{ return (licenseProof != nil); }

- (BOOL)licenseCracked
	{ return licenseCracked; }

- (NSString*)licenseHash
	{	return [licenseValidator hash];	}

- (NSInteger)licenseLimit
{
	NSString*	pkey = [licenseValidator key];

	if( pkey )
		return (NSInteger)[pkey characterAtIndex: 254] << 8;
	
	return 1;
}

- (void)reportCrackWithReason:(NSString*)howCracked
{
	NSLog(@"Cracked with reason: %@", howCracked);
	
	licenseCracked = YES;
	
	// Other response
}

- (BOOL)registerLicenseFromFile:(NSString*)licensePath
{
	BOOL			goodRegister = NO;
	PADLicense*		newLicense = [PADLicense licenseFromFile:licensePath];

	if( newLicense )
		goodRegister = [self changeLicenseProof:newLicense saveAsKey:kPADLicenseDataPrefKey];
	
	//	Saving the key in the preferences causes the LicenseController
	//	to open the Valid License Window if appropriate.
	
	[AppController playUISoundForBOOL:goodRegister];
	if( goodRegister == YES )
		[[DACALTreeDataSource shared] reportGoodRegistration];
		 
	return goodRegister;
}

- (BOOL)registerLicenseFromFileURL:(NSURL*)licenseURL {
    return [self registerLicenseFromFile:[licenseURL path]];
}

- (id)objectForLicenseKey:(NSString*)keyName
{
	id		foundIt = nil;
	
	if( [self licenseValid] )
		foundIt = [[self licenseProof] objectForLicenseKey:keyName];
	
	return foundIt;
}
				   
- (NSString*)stringForLicenseKey:(NSString*)keyName
	{ return (NSString*)[self objectForLicenseKey:keyName]; }

- (NSNumber*)numberForLicenseKey:(NSString*)keyName
	{ return (NSNumber*)[self objectForLicenseKey:keyName]; }

- (NSDate*)dateForLicenseKey:(NSString*)keyName
{
	NSString*	dateStr = [self stringForLicenseKey:keyName];
	NSDate*		outDate = nil;
	
	if( dateStr )
		outDate = [NSDate dateWithString:dateStr];
	
	return outDate;
}
				   
@end	//	PADLicenseService














































// blank


