#import <Cocoa/Cocoa.h>
#import "AquaticPrime.h"

@interface LicenseController : NSWindowController {
	IBOutlet NSWindow*			notLicensedWindow;
	IBOutlet NSWindow*			enterLicenseWindow;
	IBOutlet NSWindow*			requestLicenseWindow;
	IBOutlet NSWindow*			licenseWindow;

	IBOutlet NSTextField*		licenseeField;
	IBOutlet NSTextField*		licenseMailField;

	IBOutlet NSButton*			cancelBtn;
	IBOutlet NSButton*			okBtn;
	// License Notice
	IBOutlet NSButton*			enterLicenseBtn;
	IBOutlet NSButton*			visitLicenseBtn;
	// Enter License
	IBOutlet NSButton*			selectLicenseFileBtn;
	IBOutlet NSButton*			lostLicenseBtn;
	IBOutlet NSPathControl*		licensePathControl;
	// Request License
	IBOutlet NSButton*			submitRequestBtn;

	
}
 
+ (id)shared;
- (id)init;

- (IBAction)cancelBtn:(id)sender;	
- (IBAction)okBtn:(id)sender;	
// License Notice
- (IBAction)enterLicenseBtn:(id)sender;
- (IBAction)visitLicenseBtn:(id)sender;	
// Enter License
- (IBAction)selectLicenseFileBtn:(id)sender;
- (void)pathControlDoubleClick:(id)sender;	
- (IBAction)lostLicenseBtn:(id)sender;	
// Request License
- (IBAction)submitRequestBtn:(id)sender;	
- (void)updateLicensePanel;
- (void)showNotLicensed;
// Licensed
- (IBAction)closeLicensedSheet: (id)sender;
@end

@interface License : NSObject
{
	NSDictionary *			licenseDict;
	AquaticPrime *			licenseValidator;
	NSData *				licenseData;
	NSMutableString *		licenseKey;
	NSString *				licenseSignature;
}

+ (id)shared;
- (id)init;
- (AquaticPrime *)licenseValidator;
- (NSDictionary *)licenseDict;
- (void)setLicenseValidator:(AquaticPrime *)newValidator;
- (void)setLicenseData:(NSData *)data;
- (NSDictionary*)checkLicenseFile:(NSString*)licensePath;
- (BOOL)openLicenseFile:(NSString*)licensePath ;
- (BOOL*)licenseValid;
- (int)limit;
- (BOOL*)checkV;
- (BOOL)registerLicenseFromFile:(NSString*)licensePath;
@end

