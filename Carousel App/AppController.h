#import <Cocoa/Cocoa.h>
#import "DeviceWindowController.h"
#import "dacallib.h"

@interface AppController : NSObject {
	// Disc to scan
	IBOutlet NSPathControl *sourcePath;
	IBOutlet NSTextField *sourceExplainText;
	IBOutlet NSTextField *sourceLevelNum;
	IBOutlet NSTextField *sourceTitle;
	IBOutlet NSStepper *sourceLevelStepper;
	IBOutlet NSButton *sourceEjectDisc;
	// Carousel
	IBOutlet NSImageView *carouselcon;
	IBOutlet NSStepper *carouselIconStepper;
	IBOutlet NSTextField *carouselNum;
	IBOutlet NSStepper *carouselStepper;
	IBOutlet NSTextField *carouselLabel;
	IBOutlet NSTextField *carouselLabelLabel;
	IBOutlet NSTextField *carouselExplainText;
	IBOutlet NSButton *carouselResetButton;
	IBOutlet NSButton *carouselIDButton;
	
	//Slot
	IBOutlet NSTextField *slotNum;
	IBOutlet NSStepper *slotStepper;
	IBOutlet NSButton *slotGotoButton;
	IBOutlet NSButton *slotCloseButton;
	IBOutlet NSTextField *slotLabel;
	IBOutlet NSButton *autoEjectButton;
	IBOutlet NSButton *noDiscButton;
	IBOutlet NSButton *createButton;
	IBOutlet NSProgressIndicator *createProgress;
	
	// Restore view
	IBOutlet NSTabView *carouselTable;
	IBOutlet NSTabView *slotTable;
	IBOutlet NSTabView *contentTable;
	
	IBOutlet NSWindow *appWindow;
	IBOutlet NSImageView *windowIcon;
	
	// Driver Window
	DeviceWindowController *deviceWindow;
	
	NSWorkspace *workSpace;
	NSMutableArray*	deviceList;
	
	DACALDeviceRef carouselCount;
	NSInteger autoEject;
	NSInteger noDisc;
		
	NSString *_title;
	NSString *_slotNum;
}

// Disc to scan
- (IBAction) ejectDiscButtonClicked:(id)sender;
- (IBAction) sourceButtonClicked:(id)sender;
- (IBAction) scanLevelStepperClicked:(id)sender;
// Carousel
- (IBAction) carouselStepperClicked:(id)sender;
- (IBAction) carouselIconStepperClicked:(id)sender;
- (IBAction) carouselResetButtonClicked:(id)sender;
- (IBAction) carouselIdButtonClicked:(id)sender;
// Slot
- (IBAction) slotStepperClicked:(id)sender;
- (IBAction) slotGotoSlotButtonClicked:(id)sender;
- (IBAction) slotCloseButtonClicked:(id)sender;
- (IBAction) createButtonClicked:(id)sender;
- (IBAction) autoEjectClicked:(id)sender;
- (IBAction) noDiscClicked:(id)sender;

- (void) updateExplainText:(NSPathControl *)pathControl withTextField:(NSTextField *)textField  withText:(NSString *)text;	
- (void) updateSourceUI:(Boolean)enable;
- (void) updateCarouselUI:(Boolean)enable ;
- (void) setDeviceWindow:(DeviceWindowController*)window;
- (NSWorkspace*) workSpace;

@property (copy) NSString *_title;
@property (copy) NSString *_slotNum;
@end

