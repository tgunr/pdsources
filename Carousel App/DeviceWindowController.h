
void UserSystemBeep(void);

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
	IBOutlet NSTextField *promptText;
	
	int				currentIndex;
	DACALDeviceRef	currentDevice;
	DACALSlotNum	currentSlot;
	NSURL			*currentVolume;
}
- (IBAction)addDisk:(NSButton *)sender;
- (IBAction)changeBox:(NSComboBox *)sender;
- (IBAction)closeDoor:(NSButton *)sender;
- (IBAction)diskInfo:(NSButton *)sender;
- (IBAction)moveTo:(NSButton *)sender;
- (IBAction)removeDisk:(NSButton *)sender;
- (IBAction)resetBox:(NSButton *)sender;
- (IBAction)changeSlot:(NSTextField *)sender;
- (IBAction)changeSlotDial:(NSSlider *)sender;

- (void) newMediaDetected:(id)aNotification;
- (void) setPrompt:(NSString*)newText;

@end
