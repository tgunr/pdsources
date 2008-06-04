#import "DeviceWindowController.h"
#import "AppController.h"

Boolean prefAutoEject = TRUE;
Boolean prefPlaySound = TRUE;

enum {
	kSoundAlert = 0,
	kSoundError = 11,
	kSoundTrash = 13,
	kSoundHappy = 22
};

void PrefPlaySound(int theSound) {
	if( !prefPlaySound ) return;

	if( theSound == kSoundAlert ) AlertSoundPlay();
	else AlertSoundPlayCustomSound( (SystemSoundActionID)theSound );

	return;
}

@implementation DeviceWindowController

- (void)logReport:(NSString*) whyString {

	NSString*	uuidString;

	if( whyString == NULL ) whyString = @"Current";
	uuidString =  (NSString*)CFUUIDCreateString(NULL,DACALCommandCopyUUID( currentIndex+1, NULL ));
	NSLog( @"%@ Device: %@ Index: %i\n", whyString, uuidString, currentIndex );
	CFRelease( uuidString );
}

- (void) updateSourceUI:(BOOL)enable {
	if((enable) && (currentVolume != NULL)) {
			NSString * sTitle = [currentVolume path];
			NSArray *pathComponents = [sTitle pathComponents];
			NSUInteger pathCount = [pathComponents count];
			sTitle = [pathComponents objectAtIndex:pathCount - 1];
			[diskTitle setStringValue: sTitle];
			[self setPrompt: @"New source disk found."];
	} else {
		[diskTitle setStringValue: @""];
		[self setPrompt: (NSString*)NULL];
	}
}

- (void) updateCurrentSlot {
	NSString*	foundTitle;

	currentSlot = [slotText intValue];
	if( currentDevice ) foundTitle = (NSString*)DACALSlotCopyTitle( currentDevice, currentSlot, NULL );
	if( foundTitle != NULL ) [diskTitle setStringValue:foundTitle ];
	else [diskTitle setStringValue:@""];
	
	[buttonSlotDial setIntValue:currentSlot];
}

- (void)selectDeviceIndex:(int)newBox {
	currentIndex = newBox;
	[deviceList selectItemAtIndex:(currentIndex)];
	if(currentDevice != 0) CFRelease( (void*)currentDevice );
	currentDevice = (DACALDeviceRef)DACALCommandCopyUUID( currentIndex+1, NULL );
	
	if(currentDevice != 0) {
		[buttonSlotDial setMaxValue:DACALCommandGetSlotCount( currentDevice )];
		[slotText setIntValue: [buttonSlotDial intValue]];
		[self updateCurrentSlot];
	}
	
	[self setPrompt:NULL];
	[self logReport:@"Selection Changed. "];
	
}

- (void) setPrompt:(NSString*)newText {

	if( newText == NULL ) {
		DACALCount count = DACALDevicesGetCount();
		newText = [NSString stringWithFormat:@"%i carousel%@ found.", count, (count==1) ? @"" : @"s"];
	}
	[promptText setStringValue:newText];
	[promptText setNeedsDisplay];
}

- (void)updateDeviceList {

	int				index; 
	DACALCount		count = DACALDevicesGetCount();
	NSMutableArray*	ourArray = [NSMutableArray arrayWithCapacity:count]; 
	NSString*		workString;
	NSString*		userName = (NSString*)CSCopyUserName( TRUE );
	NSString*		userPlural = @"\'s";								// NOTE: Handle plurals better!
	NSString*		defaultName = @"%@%@ Carousel %i";
	BOOL			haveAny = (count != 0);
	
	for( index=0; index<count; index++ ) {
		workString = (NSString*)DACALCommandCopyName( index+1, NULL );
		if( workString == NULL ) workString = [NSString stringWithFormat:defaultName, userName, userPlural, index+1];
		[ourArray addObject:workString];

		currentIndex = index;
		[self logReport:@"Added Device. "];
		
//		[workString release];
	}

	[deviceList removeAllItems];
	[deviceList addItemsWithObjectValues:ourArray];
	if( haveAny ) {
		[self selectDeviceIndex:0];
	} else {
		currentIndex = 0;
		currentDevice = 0;
	}
	[self updateCurrentSlot];
	
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
	
	if( haveAny ) workString = NULL;
	else workString = @"Please connect your device USB cable or reset the power.";
	[self setPrompt:workString];
	
	if( userName != NULL ) [ userName release ];
}

// -------------------------------------------------------------------------------
//	awakeFromNib
// -------------------------------------------------------------------------------
- (void)awakeFromNib {
	currentIndex = 0;
	currentDevice = 0;
	[self updateDeviceList];
	
	[((AppController*)[[NSApplication sharedApplication] delegate]) setDeviceWindow:self];
}

- (void) newMediaDetected:(id)aNotification {
	NSArray *newMounts = [[((AppController*)[[NSApplication sharedApplication] delegate]) workSpace] mountNewRemovableMedia];
	NSString *lastMount = [newMounts lastObject];	
	currentVolume = [[NSURL fileURLWithPath: lastMount] retain];
	
	[self updateSourceUI:TRUE];	
}

- (IBAction)addDisk:(NSButton *)sender {

	DACALCount		indexLevel = 1;
	DACALResult		indexResult;
	DACALSlotNum	indexSlot = [slotText intValue];

	[busyIndicator setHidden:FALSE];
	[busyIndicator startAnimation:self];
	[self setPrompt:@"Indexing source disk..."];

	indexResult = DACALSlotCreateIndex( currentDevice, indexSlot, (CFStringRef)[diskTitle stringValue], indexLevel, (CFURLRef)currentVolume );
	if( indexResult == 0 ) {
		[self moveTo:sender];
		indexSlot++;											// Ideally this would find the next *empty* slot.
		if( indexSlot > DACALCommandGetSlotCount(currentDevice) ) indexSlot = 1;
		[slotText setIntValue:indexSlot];	
		[buttonSlotDial setIntValue:indexSlot];
		[self updateCurrentSlot];

		if( (prefAutoEject) && (currentVolume != NULL) ) {
			[[((AppController*)[[NSApplication sharedApplication] delegate]) workSpace] unmountAndEjectDeviceAtPath: [currentVolume path]];
			currentVolume = NULL;
			[self updateSourceUI:FALSE];
		}
		
		[self setPrompt:@"Disk index saved."];
		PrefPlaySound( kSoundHappy );
	} else {
		[self setPrompt:@"Error: Disk index was not saved."];
		PrefPlaySound( kSoundError );	
	}
	
	[busyIndicator setHidden:TRUE];
	[busyIndicator stopAnimation:self];		
}

- (IBAction)changeBox:(NSComboBox *)sender {
	int	newIndex = [sender indexOfSelectedItem];

	if( newIndex == -1 ) {
			// Should probably confirm this
			DACALCommandSetName( currentDevice, (CFStringRef)[[sender stringValue] copy] );
			[sender removeItemAtIndex: currentIndex];
			[sender insertItemWithObjectValue: [[sender stringValue] copy] atIndex: currentIndex ];
			
			[self setPrompt:@"Carousel renamed."];
			[self logReport:@"Name Changed.  "];
			
	} else {
		if( newIndex != currentIndex ) [self selectDeviceIndex: newIndex];
	}
}


- (IBAction)closeDoor:(NSButton *)sender {

	[self logReport:@"Command: Close Door "];

	DACALCommandCloseDoor( currentDevice );
	[self setPrompt:NULL];
}

- (IBAction)diskInfo:(NSButton *)sender {
    NSLogFunc;
	PrefPlaySound( kSoundAlert );
	[self setPrompt:@"Unimplemented Function!"];
}

- (IBAction)moveTo:(NSButton *)sender {
	currentSlot = [slotText intValue];

	[self logReport:@"Command: Open Door "];
	
	DACALCommandMoveToSlot( currentDevice, currentSlot );
	[self setPrompt:@"Slot opened."];
}

- (IBAction)removeDisk:(NSButton *)sender {
	currentSlot = [slotText intValue];

	[self logReport:@"Command: Delete Slot "];
	
	DACALSlotDeleteIndex( currentDevice, currentSlot );

	PrefPlaySound( kSoundTrash );	

	[self updateCurrentSlot];
	[self setPrompt:@"Slot cleared."];
}

- (IBAction)resetBox:(NSButton *)sender {

	[self logReport:@"Command: Reset "];

	DACALCommandReset( currentDevice );
	[self setPrompt:NULL];
}

- (IBAction)changeSlot:(NSTextField *)sender {
	if( [slotText intValue] != currentSlot ) [self updateCurrentSlot];
}

- (IBAction)changeSlotDial:(NSSlider *)sender {

	if( currentSlot != [buttonSlotDial intValue] ) {
		[slotText setIntValue: [buttonSlotDial intValue]];
		[self updateCurrentSlot];
	}
		
}
@end
