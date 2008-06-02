#import <Cocoa/Cocoa.h>
#import "pms.h"
#import "dacallib.h"

@interface DeviceWindowController : NSObject {
    IBOutlet NSProgressIndicator *busyIndicator;
    IBOutlet NSButton *buttonAddDisk;
    IBOutlet NSButton *buttonCloseDoor;
    IBOutlet NSButton *buttonDiskInfo;
    IBOutlet NSButton *buttonMoveTo;
    IBOutlet NSButton *buttonRemoveDisk;
    IBOutlet NSButton *buttonReset;
    IBOutlet NSSlider *buttonSlotDial;
    IBOutlet NSImageView *deviceImage;
    IBOutlet NSComboBox *deviceList;
    IBOutlet NSTextField *diskTitle;
    IBOutlet NSTextField *slotText;
	
	int				currentIndex;
	DACALDeviceRef	currentDevice;
	DACALSlotNum	currentSlot;
}
- (IBAction)addDisk:(NSButton *)sender;
- (IBAction)changeBox:(NSComboBox *)sender;
- (IBAction)closeDoor:(NSButton *)sender;
- (IBAction)diskInfo:(NSButton *)sender;
- (IBAction)moveTo:(NSButton *)sender;
- (IBAction)removeDisk:(NSButton *)sender;
- (IBAction)resetBox:(NSButton *)sender;
- (void)textDidChange:(NSNotification *)aNotification;
@end
