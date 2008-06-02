#import "DeviceWindowController.h"

@implementation DeviceWindowController

- (void)updateDeviceList {

	int				index; 
	DACALCount		count = DACALDevicesGetCount();
	NSMutableArray*	ourArray = [NSMutableArray arrayWithCapacity:count]; 
	NSString*		workString;
	NSString*		defaultName = @"Carousel %i";
	BOOL			haveAny = (count != 0);
	
	for( index=0; index<count; index++ ) {
		workString = (NSString*)DACALCommandCopyName( index, NULL );
		if( workString == NULL ) workString = [NSString stringWithFormat:defaultName, index];
		[ourArray addObject:workString];
		[workString release];
	}

	[deviceList removeAllItems];
	[deviceList addItemsWithObjectValues:ourArray];
	if( haveAny ) {
		currentIndex = 0;
		[deviceList selectItemAtIndex:(currentIndex)];
		currentDevice = (DACALDeviceRef)DACALCommandCopyUUID( currentIndex, NULL );
		currentDevice = 0;
	} else {
		currentIndex = 0;
		currentDevice = 0;
	}
	
	[deviceList			setEnabled:haveAny];
	[slotText			setEnabled:haveAny];
	[diskTitle			setEnabled:haveAny];
	
	[buttonAddDisk		setEnabled:haveAny];
	[buttonCloseDoor	setEnabled:haveAny];
	[buttonDiskInfo		setEnabled:haveAny];
	[buttonMoveTo		setEnabled:haveAny];
	[buttonRemoveDisk	setEnabled:haveAny];
	[buttonReset		setEnabled:haveAny];
	[buttonSlotDial		setEnabled:haveAny];
	
}


// -------------------------------------------------------------------------------
//	awakeFromNib
// -------------------------------------------------------------------------------
- (void)awakeFromNib {
	[self updateDeviceList];

}

- (IBAction)addDisk:(NSButton *)sender {
	NSLogFunc;
}

- (IBAction)changeBox:(NSComboBox *)sender {
    NSLogFunc;
}

- (IBAction)closeDoor:(NSButton *)sender {
	DACALCommandCloseDoor( currentDevice );
}

- (IBAction)diskInfo:(NSButton *)sender {
    NSLogFunc;
}

- (IBAction)moveTo:(NSButton *)sender {
	currentSlot = [slotText intValue];

	DACALCommandMoveToSlot( currentDevice, currentSlot );
}

- (IBAction)removeDisk:(NSButton *)sender {
    NSLogFunc;
}

- (IBAction)resetBox:(NSButton *)sender {
	DACALCommandReset( currentDevice );
}
@end
