#import "PADPrefsController.h"

@implementation PADPrefsController

- (void)awakeFromNib {
	
	if( tabToolbar ) [tabToolbar setSelectedItemIdentifier:[[[tabToolbar items] objectAtIndex:0] itemIdentifier]];
		
	
}


- (NSArray *)toolbarSelectableItemIdentifiers:(NSToolbar *)toolbar {
	
	NSArray* theItems = [toolbar items];
	NSInteger theCount = [theItems count];
	NSInteger index;
	NSMutableArray* theArray = [NSMutableArray arrayWithCapacity:theCount];
	
	for(index=0; index<theCount; index++)
		[theArray addObject:[[theItems objectAtIndex:index] itemIdentifier]];
	
//	NSLog(@"Selectables: %@", theArray);
	
	return theArray;
}



- (IBAction)clickTool:(NSToolbarItem*)sender {
    
	if( tabView ) [tabView selectTabViewItemWithIdentifier: [sender label]];
	if( tabToolbar ) [tabToolbar setSelectedItemIdentifier: [sender itemIdentifier]];
}

@end
