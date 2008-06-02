#import "DeviceWindowController.h"

void UserSystemBeep(void) {
	AlertSoundPlay();
}

@implementation DeviceWindowController

- (NSString*)diskTitleForSlot:(int)theSlot {
	return( (NSString*)NULL );
}

- (void)selectDeviceIndex:(int)newBox {
	currentIndex = newBox;
	[deviceList selectItemAtIndex:(currentIndex)];
	if(currentDevice != 0) [(id)currentDevice release];
	currentDevice = (DACALDeviceRef)DACALCommandCopyUUID( currentIndex, NULL );
}

- (void)updateDeviceList {

	int				index; 
	DACALCount		count = DACALDevicesGetCount();
	NSMutableArray*	ourArray = [NSMutableArray arrayWithCapacity:count]; 
	NSString*		workString;
	NSString*		defaultName = @"Carousel %i";
	BOOL			haveAny = (count != 0);
	
	for( index=0; index<count; index++ ) {
		workString = (NSString*)DACALCommandCopyName( index, NULL );
		if( workString == NULL ) workString = [NSString stringWithFormat:defaultName, index+1];
		[ourArray addObject:workString];
		[workString release];
	}

	[deviceList removeAllItems];
	[deviceList addItemsWithObjectValues:ourArray];
	if( haveAny ) {
		[self selectDeviceIndex:0];
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
	currentIndex = 0;
	currentDevice = 0;
	[self updateDeviceList];
}

- (IBAction)addDisk:(NSButton *)sender {
	NSLogFunc;
	UserSystemBeep();
}

- (IBAction)changeBox:(NSComboBox *)sender {
	int	newIndex = [sender indexOfSelectedItem];

	if( newIndex == -1 ) {
			// Should probably confirm this
			DACALCommandSetName( currentDevice, (CFStringRef)[[sender stringValue] copy] );
			[sender removeItemAtIndex: currentIndex];
			[sender insertItemWithObjectValue: [[sender stringValue] copy] atIndex: currentIndex ];
	} else {
		if( newIndex != currentIndex ) [self selectDeviceIndex: newIndex];
	}
}


- (IBAction)closeDoor:(NSButton *)sender {
	DACALCommandCloseDoor( currentDevice );
}

- (IBAction)diskInfo:(NSButton *)sender {
    NSLogFunc;
	UserSystemBeep();
}

- (IBAction)moveTo:(NSButton *)sender {
	currentSlot = [slotText intValue];

	DACALCommandMoveToSlot( currentDevice, currentSlot );
}

- (IBAction)removeDisk:(NSButton *)sender {
    NSLogFunc;
	UserSystemBeep();
}

- (IBAction)resetBox:(NSButton *)sender {
	DACALCommandReset( currentDevice );
}
@end
