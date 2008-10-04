#import <Cocoa/Cocoa.h>
#import "AquaticPrime.h"

@interface LicenseController : NSWindowController {
	IBOutlet NSWindow*			notLicensedWindow;
	IBOutlet NSWindow*			enterLicenseWindow;
	IBOutlet NSWindow*			requestLicenseWindow;

	IBOutlet NSTextField*		licenseeField;
	IBOutlet NSTextField*		licenseMailField;

	IBOutlet NSButton*			selectLicenseFileBtn;
	IBOutlet NSButton*			requestLicenseBtn;
	IBOutlet NSButton*			enterLicenseBtn;
	IBOutlet NSButton*			cancelLicenseBtn;
	IBOutlet NSButton*			visitLicenseBtn;
	IBOutlet NSButton*			lostLicenseBtn;
	IBOutlet NSButton*			submitRequestBtn;

	IBOutlet NSPathControl*		licensePathControl;
	
}
 
+ (id)shared;
- (id)init;
- (IBAction)selectLicenseFileBtn:(id)sender;
- (IBAction)requestLicenseBtn:(id)sender;
- (IBAction)enterLicenseBtn:(id)sender;
- (IBAction)cancelLicenseBtn:(id)sender;	
- (IBAction)visitLicenseBtn:(id)sender;	
- (IBAction)submitRequestBtn:(id)sender;	
- (IBAction)lostLicenseBtn:(id)sender;	
- (void)pathControlDoubleClick:(id)sender;	
- (void)updateLicensePanel;
- (void)showNotLicensed;

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

