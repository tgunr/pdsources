#import <Cocoa/Cocoa.h>
#import "AquaticPrime.h"

@interface LicenseController : NSWindowController
{
	IBOutlet NSWindow*			notLicensedWindow;
	IBOutlet NSWindow*			enterLicenseWindow;
	IBOutlet NSWindow*			requestLicenseWindow;
	IBOutlet NSWindow*			licenseWindow;

	IBOutlet NSButton*			okBtn;
	
	// License Notice
	IBOutlet NSButton*			enterLicenseBtn;
	IBOutlet NSButton*			demoLicenseBtn;
	IBOutlet NSButton*			visitLicenseBtn;
	
	// Enter License
	IBOutlet NSButton*			selectLicenseFileBtn;
	IBOutlet NSButton*			requestLicenseBtn;
	IBOutlet NSPathControl*		licensePathControl;
	
	// Request License
	IBOutlet NSTextField*		licenseeField;
	IBOutlet NSTextField*		licenseMailField;
	IBOutlet NSTextField*		licenseInvoiceCode;
	IBOutlet NSButton*			submitRequestBtn;
	
	// Valid License
	IBOutlet NSTextField*		validUserName;
	IBOutlet NSTextField*		validUserMail;
	IBOutlet NSTextField*		validUserMessage;
	
	NSString*					controllerState;
}
 
+ (id)sharedLicenseController;
- (id)init;

- (void)runNotLicensedModalWindow;
- (void)runChooseLicenseWindow;
- (void)runHaveLicenseWindow;

- (IBAction)chooseAppLicensedMenu:(id)sender;
- (IBAction)chooseRequestLicenseMenu:(id)sender;

- (IBAction)cancelLicenseBtn:(id)sender;	
- (IBAction)okBtn:(id)sender;	

// License Notice
- (IBAction)enterLicenseBtn:(id)sender;
- (IBAction)visitLicenseBtn:(id)sender;	
- (IBAction)demoLicenseBtn:(id)sender;

// Enter License
- (IBAction)selectLicenseFileBtn:(id)sender;
- (void)pathControlDoubleClick:(id)sender;	
- (IBAction)requestLicensePressed:(id)sender;	

// Request License
- (IBAction)submitBtnPressed:(id)sender;	
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
- (BOOL)licenseValid;
- (int)limit;
- (BOOL*)checkV;
- (BOOL)registerLicenseFromFile:(NSString*)licensePath;
@end

