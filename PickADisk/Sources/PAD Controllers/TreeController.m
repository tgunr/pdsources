//
//  TreeController.m
//  DragNDropOutlineView
//
//  Copyright 2008 PolyMicro Systems. All rights reserved.
//

#import "TreeController.h"
#import "PADIndexToolbarController.h"
#import "PADOutlineView.h"

@interface TreeController(Private)
- (void)_addNewDataToSelection:(SimpleTreeNode *)newChild;
@end

// ================================================================
// Useful Macros
// ================================================================

#define DragDropSimplePboardType 	@"MyCustomOutlineViewPboardType"


@implementation TreeController

- (TreeController *)init {
    if ((self = [super init])) {
		
	}

    return self; 
}

- (void)dealloc {
    //[treeData release];
    [draggedNodes release];

	//if( treeDataSource != nil ) [treeDataSource release];
	[treeData release];
	[outlineView release];
	[super dealloc];
}


- (void)awakeFromNib {

	// Install Data for Tree
	if( treeDataSource != nil )
        [self setTreeRoot:[treeDataSource performSelector:@selector(createInitialTree:) withObject:self]];

	// Initialize the View
	if( treeDataSource != nil )
        [treeDataSource performSelector:@selector(outlineViewInit)];
	
	// Setup doubles
	[[self outlineView]
     setDoubleAction:@selector(outlineViewDoubleAction:)];
	
}


- (void)recreateInitialTree
{
	// Install Data for Tree
	if( treeDataSource != nil ) [treeDataSource performSelector:@selector(recreateInitialTree)];
}

- (NSArray *)draggedNodes { 
    return draggedNodes; 
}

- (NSArray *)selectedNodes { return [outlineView allSelectedItems]; }

- (BOOL)allowOnDropOnGroup					{ return allowOnDropOnGroup; }
- (BOOL)allowOnDropOnLeaf					{ return allowOnDropOnLeaf; }
- (BOOL)allowBetweenDrop					{ return allowBetweenDrop; }
- (BOOL)allowGroupRowLook					{ return allowGroupRowLook; }
- (BOOL)allowButtonCellsToChangeSelection   { return allowButtonCellsToChangeSelection; }
- (BOOL)onlyAcceptDropOnRoot				{ return onlyAcceptDropOnRoot; }
- (BOOL)allowToggleVerticalBeginsDrag		{ return allowToggleVerticalBeginsDrag; }

- (void)setAllowOnDropOnGroup:(BOOL)allow					{ allowOnDropOnGroup = allow; if(outlineView) [outlineView setNeedsDisplay:YES]; }
- (void)setAllowOnDropOnLeaf:(BOOL)allow					{ allowOnDropOnLeaf = allow; if(outlineView) [outlineView setNeedsDisplay:YES]; }
- (void)setAllowBetweenDrop:(BOOL)allow						{ allowBetweenDrop = allow; if(outlineView) [outlineView setNeedsDisplay:YES]; }
- (void)setAllowGroupRowLook:(BOOL)allow					{ allowGroupRowLook = allow; if(outlineView) [outlineView setNeedsDisplay:YES]; }
- (void)setAllowButtonCellsToChangeSelection:(BOOL)allow	{ allowButtonCellsToChangeSelection = allow; if(outlineView) [outlineView setNeedsDisplay:YES]; }
- (void)setAllowToggleVerticalBeginsDrag:(BOOL)allow		{ allowToggleVerticalBeginsDrag = allow; [outlineView setVerticalMotionCanBeginDrag:allow]; if(outlineView) [outlineView setNeedsDisplay:YES]; }
- (void)setOnlyAcceptDropOnRoot:(BOOL)allow					{ onlyAcceptDropOnRoot = allow; if(outlineView) [outlineView setNeedsDisplay:YES]; }

- (SimpleTreeNode*)treeRoot {
    return treeData;
}
	
- (void)setTreeRoot:(SimpleTreeNode*)root
{
	if( treeData == root ) return;
	if( root != NULL ) [root retain];
	if( treeData != NULL ) [treeData release];
	treeData = root;
    [outlineView reloadData];
	//[outlineView setNeedsDisplay:YES];
}

- (void)addTreeRoot:(SimpleTreeNode *)newChild
{
    NSInteger childIndex = 0;
    SimpleTreeNode *selectedNode = treeData;
    TreeNode *parentNode = nil;
	
	if( treeData == nil ) {
		[newChild sortChildrenUsingDescriptors:[outlineView sortDescriptors]];
		[self setTreeRoot:newChild];
		goto AFTERRELOAD;
	}

    if ([[selectedNode nodeData] isGroup]) { 
	parentNode = selectedNode; 
	childIndex = 0; 
    }
    else { 
	parentNode = [selectedNode nodeParent]; 
	childIndex = [parentNode indexOfChildIdenticalTo:selectedNode]+1; 
    }
    
    [parentNode insertChild: newChild atIndex: childIndex];
 	[parentNode sortChildrenUsingDescriptors:[outlineView sortDescriptors]];	
   [outlineView reloadData];
	
AFTERRELOAD:
	[newChild recursiveReExpandInView:outlineView];
}

- (id)treeDataSource { return treeDataSource; }

- (PADOutlineView*)outlineView { return outlineView; }
- (void)setOutlineView:(PADOutlineView*)view
{
	if( outlineView != nil )
        [outlineView release];
	if( view != nil )
        [view retain];
	outlineView = view;
}

//	Returns the NSUndoManager for the outline view
- (NSUndoManager*)undoManager
{
	NSOutlineView*		ourView = [self outlineView];
	
	if( ourView )
		return [ourView undoManager];
	
	return nil; 
}

// ================================================================
// Target / action methods. (most wired up in IB)
// ================================================================

- (void)addGroup:(id)sender {
    // Adds a new expandable entry to the current selection, by inserting a new group node.
    [self _addNewDataToSelection:[SimpleTreeNode treeNodeWithData: [SimpleNodeData groupDataWithName:@"New Group"]]];
}

- (void)addLeaf:(id)sender {
    // Adds a new leaf entry to the current selection, by inserting a new leaf node.
    [self _addNewDataToSelection:[SimpleTreeNode treeNodeWithData: [SimpleNodeData leafDataWithName:@"New Leaf"]]];
}

- (void)addDataToTree:(SimpleTreeNode*)newChild startEdit:(BOOL)doEdit
{
	NSInteger childIndex = 0, newRow = 0;
//		NSArray *selectedNodes = [self selectedNodes];
//		SimpleTreeNode *selectedNode = ([selectedNodes count] ? [selectedNodes objectAtIndex:0] : treeData);
//		SimpleTreeNode *selectedNode = treeData;
//		TreeNode *parentNode = nil;
		
/*		if ([[selectedNode nodeData] isGroup]) { 
			parentNode = selectedNode; 
			childIndex = 0; 
		}
		else { 
			parentNode = [selectedNode nodeParent]; 
			childIndex = [treeData numberOfChildren];// [parentNode indexOfChildIdenticalTo:selectedNode]+1; 
		}
		
		[parentNode insertChild: newChild atIndex: childIndex];
*/
	
	
	
	childIndex = [treeData numberOfChildren];
	[treeData insertChild:newChild atIndex:childIndex];
	[outlineView reloadData];
		
	newRow = [outlineView rowForItem: newChild];
	if (newRow>=0) [outlineView selectRow: newRow byExtendingSelection: NO];
	if( (doEdit==YES) && (newRow>=0))
		[outlineView editColumn:0 row:newRow withEvent:nil select:YES];		
}


- (void)outlineViewAction:(id)olv {
    // This message is sent from the outlineView as it's action (see the connection in IB).

	// Tell data source
	if( treeDataSource != nil )
		[treeDataSource performSelector:@selector(outlineViewAction:) withObject:self];

}

- (void)outlineViewDoubleAction:(id)olv {
	// This message is sent from th outlineView as it's double-action (see awakeFromNib)

	// Tell data source
	if( treeDataSource != nil ) [treeDataSource performSelector:@selector(outlineViewDoubleAction:) withObject:self];
}

- (void)deleteSelections:(id)sender {
    NSArray *selection = [self selectedNodes];
    
    // Tell all of the selected nodes to remove themselves from the model.
    [selection makeObjectsPerformSelector: @selector(removeFromParent)];
	[self deletedSelections];
}

- (void)deletedSelections
{
    [outlineView deselectAll:nil];
    [outlineView reloadData];
}

- (void)toggleVerticalBeginsDrag:(id)sender {
    // This message is sent from the "Vertical Motion Begins Drag" check box.
    [outlineView setVerticalMotionCanBeginDrag: [sender state]];
}

- (IBAction)sortData:(id)sender {
    NSArray *itemsToSelect = [self selectedNodes];
    [treeData recursiveSortChildren];
    [outlineView reloadData];
    [outlineView selectItems: itemsToSelect byExtendingSelection: NO];
}

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem {
	
	return [treeDataSource validateMenuItem:menuItem];
	
    if ([menuItem action]==@selector(deleteSelections:)) {
	// The delete selection item should be disabled if nothing is selected.
	return ([[self selectedNodes] count] > 0);
    }    
    return YES;
}


// ================================================================
//  NSOutlineView data source methods. (The required ones)
// ================================================================

// Required methods. These methods must handle the case of a "nil" item, which indicates the root item.
- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item {
    SimpleTreeNode *node = (item == nil) ? treeData : item;
    return [node childAtIndex:index];
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item {
    SimpleTreeNode *node = (item == nil) ? treeData : item;
    return [[node nodeData] isExpandable];
}

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item {
    SimpleTreeNode *node = (item == nil) ? treeData : item;
    return [node numberOfChildren];
}

- (id)outlineView:(NSOutlineView *)ov objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
    id objectValue = nil;
    
    // The return value from this method is used to configure the state of the items cell via setObjectValue:
	if( treeDataSource != nil )
		objectValue = [treeDataSource performSelector:@selector(objectValueForTableColumn:byItem:) withObject:tableColumn withObject:item];
	else
		NSLog(@"Unknown Column: %@", [tableColumn identifier]);

    return objectValue;
}

// Optional method: needed to allow editing.
- (void)outlineView:(NSOutlineView *)ov setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
	//	Here, we call the data source to fill in the value.
	if( treeDataSource != nil )
		[treeDataSource setObjectValue:object forTableColumn:tableColumn byItem:item];
}

/*  
 *	These are additional column data suppliers from the original example:
 *
    } else if ([[tableColumn identifier] isEqualToString:COLUMNID_IS_EXPANDABLE]) {
	[data setExpandable:[object boolValue]];
	if (![data isExpandable] && [outlineView isItemExpanded:item]) {
            [outlineView collapseItem:item];            
        }
    } else if ([[tableColumn identifier] isEqualToString:COLUMNID_NODE_KIND]) {
	// We don't allow editing of this column, so we should never actually get here.
    } else if ([[tableColumn identifier] isEqualToString:COLUMID_IS_SELECTABLE]) {
	[data setSelectable:[object boolValue]];
    }
}
*/


// We can return a different cell for each row, if we want
- (NSCell *)outlineView:(NSOutlineView *)ov dataCellForTableColumn:(NSTableColumn *)tableColumn item:(id)item {
    ImageAndTextCell* outCell = [tableColumn dataCell];
	[outCell setRepresentedObject:item];
	// If we return a cell for the 'nil' tableColumn, it will be used as a "full width" cell and span all the columns
    if ([self allowGroupRowLook] && (tableColumn == nil)) {
        // TODO: 2012-08-25 Exception thrown here after all night running and reactivated
        if ([[item nodeData] isGroup]) {
            // We want to use the cell for the name column, but we could construct a new cell if we wanted to, or return a different cell for each row.
            return [[outlineView tableColumnWithIdentifier:COLUMNID_NAME] dataCell];
        }
    }
	
	// If the item is a new cell, startup busy if necessary
	if ((tableColumn != nil) && [[tableColumn identifier] isEqualToString:COLUMNID_NAME])
		[outCell setBusy: [item busy]];
	
    return outCell;
}

// To get the "group row" look, we implement this method.
- (BOOL)outlineView:ov isGroupItem:(id)item {
	if( treeDataSource != nil )
		return [treeDataSource outlineView:ov isGroupItem:item];
	else
		return [[item nodeData] isGroup] && [self allowGroupRowLook];
}

- (BOOL)outlineView:(NSOutlineView *)ov shouldExpandItem:(id)item {
	if( treeDataSource != nil )
		return [treeDataSource outlineView:ov shouldExpandItem:item];
	else
		return [[item nodeData] isGroup];
}

- (BOOL)outlineView:(NSOutlineView *)ov shouldCollapseItem:(id)item {
	if( treeDataSource != nil )
		return [treeDataSource outlineView:ov shouldCollapseItem:item];
	else
		return [[item nodeData] isGroup];
}

- (void)outlineViewItemWillExpand:(NSNotification *)notification {
	SimpleTreeNode*		theItem = [[notification userInfo] valueForKey:@"NSObject"];
	
	if( theItem ) 
	{
		[[theItem nodeData] setExpanded:YES];
		[theItem sortChildrenUsingDescriptors:[[self outlineView] sortDescriptors]];
	}
}

- (void)outlineViewItemDidExpand:(NSNotification *)notification
{
	SimpleTreeNode*		theItem = [[notification userInfo] valueForKey:@"NSObject"];
	
	if( treeDataSource != nil )
		[treeDataSource performSelector:@selector(nodeDidExpand:) withObject:theItem];
}

- (void)outlineViewItemDidCollapse:(NSNotification *)notification {
	SimpleTreeNode*		theItem = [[notification userInfo] valueForKey:@"NSObject"];
	
	if( theItem ) [[theItem nodeData] setExpanded:NO];
	
	if( treeDataSource != nil )
		[treeDataSource performSelector:@selector(nodeDidCollapse:) withObject:theItem];	
}

- (void)outlineViewSelectionDidChange:(NSNotification *)notification
{
	if( treeDataSource != nil )
		[treeDataSource performSelector:@selector(selectionDidChange)];
}


- (void)outlineView:(NSOutlineView *)ov willDisplayOutlineCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn item:(id)item {
//	if( [[item nodeData] isExpanded] ) [ov expandItem:item];
}

- (void)outlineView:(NSOutlineView *)ov willDisplayCell:(NSCell *)cell forTableColumn:(NSTableColumn *)tableColumn item:(id)item {    
    SimpleNodeData *data = [item nodeData];
    if ((tableColumn == nil) || [[tableColumn identifier] isEqualToString:COLUMNID_NAME]) {

	// Make sure the image and text cell has an image.  If not, give it something random.
	//if (![data iconRep]) [data setIconRep:[self _randomIconImage]];
        // We know that the cell at this column is our image and text cell, so grab it
        ImageAndTextCell *imageAndTextCell = (ImageAndTextCell *)cell;
	// Set the image here since the value returned from outlineView:objectValueForTableColumn:... didn't specify the image part...
	if ([data iconRep])
        [imageAndTextCell setImage:[data iconRep]];
	else
        [imageAndTextCell setImage:nil];
	}
/*
 *	These are additional column data suppliers from the original example:
 *
    } else if ([[tableColumn identifier] isEqualToString:COLUMNID_IS_EXPANDABLE]) {
	[cell setEnabled:[data isGroup]];
        // On MacOS 10.5 and later, in willDisplayCell: we can dynamically set the contextual menu (right click menu) for a particular cell. If nothing is set, then the contextual menu for the NSOutlineView itself will be used. We will set a different menu for the "Expandable?" column, and leave the default one for everything else.
        [cell setMenu:expandableColumnMenu];
    }
*/ 
   // For all the other columns, we don't do anything.
}

- (BOOL)outlineView:(NSOutlineView *)ov shouldEditTableColumn:(NSTableColumn *)tc item:(id)item
{
	if( treeDataSource != nil )
		if( [treeDataSource performSelector:@selector(shouldEditTableColumn:item:) withObject:tc withObject:item] == 0 )
            return NO;
	return YES;
}

- (BOOL)outlineView:(NSTableView *)outView shouldSelectTableColumn:(NSTableColumn *)tc
{
	if( treeDataSource != nil )
		if( [treeDataSource performSelector:@selector(shouldSelectColumn:) withObject:tc] == 0 )
            return NO;
	return YES;
}

- (BOOL)outlineView:(NSOutlineView *)ov shouldSelectItem:(id)item {
    // Control selection of a particular item. 
	if( treeDataSource != nil )
		return [treeDataSource outlineView:ov shouldSelectItem:item];
	else
		return [[item nodeData] isSelectable];

	return NO;
}

- (BOOL)outlineView:(PADOutlineView *)ov shouldTrackCell:(NSCell *)cell forTableColumn:(NSTableColumn *)tableColumn item:(id)item {
    // We want to allow tracking for all the button cells, even if we don't allow selecting that particular row. 
    if ([cell isKindOfClass:[NSButtonCell class]]) {
        // We can also take a peek and make sure that the part of the cell clicked is an area that is normally tracked. Otherwise, clicking outside of the checkbox may make it check the checkbox
        NSRect cellFrame = [outlineView frameOfCellAtColumn:[[outlineView tableColumns] indexOfObject:tableColumn] row:[outlineView rowForItem:item]];
        NSUInteger hitTestResult = [cell hitTestForEvent:[NSApp currentEvent] inRect:cellFrame ofView:outlineView];
        if (hitTestResult && NSCellHitTrackableArea != 0) {
            return YES;
        } else {
            return NO;
        }
    } else {
        // Only allow tracking on selected rows. This is what NSTableView does by default.
        return [outlineView isRowSelected:[outlineView rowForItem:item]];
    }
}

- (void)outlineView:(NSOutlineView *)theView sortDescriptorsDidChange:(NSArray *)oldDescriptors
{
	NSArray* selectedItems = [outlineView allSelectedItems];
	NSArray* newDescriptors = [outlineView sortDescriptors];
	
	[treeData sortExpandedChildrenUsingDescriptors:newDescriptors];
    [outlineView reloadData];
	[outlineView selectItems:selectedItems byExtendingSelection:NO];
}


- (NSString *)outlineView:(PADOutlineView *)ov toolTipForCell:(NSCell *)cell rect:(NSRectPointer)inRect tableColumn:(NSTableColumn *)tc item:(id)inItem mouseLocation:(NSPoint)inMouseLocation
{
	if( treeDataSource != nil )
		return [treeDataSource toolTipForCell:cell rect:inRect tableColumn:tc item:inItem mouseLocation:inMouseLocation];
	
	return nil;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldShowCellExpansionForTableColumn:(NSTableColumn *)tc item:(id)inItem
{
	if( treeDataSource != nil )
		return [treeDataSource shouldShowCellExpansionForTableColumn:tc item:inItem];
	
	return NO;
}

// ================================================================
//  NSOutlineView data source methods. (dragging related)
// ================================================================

// Create a fileHandle for writing to a new file located in the directory specified by 'dirpath'.  If the file basename.extension already exists at that location, then append "-N" (where N is a whole number starting with 1) until a unique basename-N.extension file is found.  On return oFilename contains the name of the newly created file referenced by the returned NSFileHandle.
NSFileHandle *NewFileHandleForWritingFile(NSString *dirpath, NSString *basename, NSString *extension, NSString **oFilename) {
    NSString *filename = nil;
    BOOL done = NO;
    NSInteger fdForWriting = -1, uniqueNum = 0;
    while (!done) {
        filename = [NSString stringWithFormat:@"%@%@.%@", basename, (uniqueNum ? [NSString stringWithFormat:@"-%ld", (long)uniqueNum] : @""), extension];
        fdForWriting = open([[NSString stringWithFormat:@"%@/%@", dirpath, filename] UTF8String], O_WRONLY | O_CREAT | O_EXCL, 0666);
        if (fdForWriting < 0 && errno == EEXIST) {
            // Try another name.
            uniqueNum++;
        } else {
            done = YES;
        }
    }

    NSFileHandle *fileHandle = nil;
    if (fdForWriting>0) {
        fileHandle = [[NSFileHandle alloc] initWithFileDescriptor:fdForWriting closeOnDealloc:YES];
    }
    
    if (oFilename) {
        *oFilename = (fileHandle ? filename : nil);
    }
    
	
    return fileHandle;
}

NSURL *NewFileURLForWritingFile(NSString *dirpath, NSString *basename, NSString *extension) {
    NSString *filename = nil;
    BOOL done = NO;
 //   NSInteger fdForWriting = -1, uniqueNum = 0;
	NSInteger uniqueNum = 0;
	NSURL*	outURL = nil;
	
    while (!done) {
        filename = [NSString stringWithFormat:@"%@%@.%@", basename, (uniqueNum ? [NSString stringWithFormat:@"-%ld", (long)uniqueNum] : @""), extension];
 //       fdForWriting = open([[NSString stringWithFormat:@"%@/%@", dirpath, filename] UTF8String], O_WRONLY | O_CREAT | O_EXCL, 0666);
 //       if (fdForWriting < 0 && errno == EEXIST) {
 //           // Try another name.
 //           uniqueNum++;
 //       } else {
            done = YES;
 //       }
    }
	
	outURL = [NSURL fileURLWithPath:filename];
	
    return outURL;
}



// We promised the files, so now lets make good on that promise!
- (NSArray *)outlineView:(NSOutlineView *)ov namesOfPromisedFilesDroppedAtDestination:(NSURL *)dropDestination forDraggedItems:(NSArray *)items {
    NSInteger i = 0, count = [items count];
    NSMutableArray *filenames = [NSMutableArray array];
    for (i=0; i<count; i++) {
//		NSString *urlFile = [NSString stringWithFormat:@"[InternetShortcut]\nURL=%@\n", [[items objectAtIndex:i] description]];
		
		
		
		NSDictionary*	urlDict = [NSDictionary dictionaryWithObject:[[items objectAtIndex:i] description] forKey:@"URL"];
		NSURL*			urlPlace = NewFileURLForWritingFile([dropDestination path], @"PromiseTestFile", @"url");
		NSLog(@"URL: %@", urlPlace);
		
		BOOL	good = [urlDict writeToURL:urlPlace atomically:NO];
		NSLog(@"Good: %@", good?@"YES":@"NO");
		
/*
        NSString *filename  = nil;
        NSFileHandle *fileHandle = NewFileHandleForWritingFile([dropDestination path], @"PromiseTestFile", @"url", &filename);
        if (fileHandle) {
			NSString *urlFile = [NSString stringWithFormat:@"[InternetShortcut]\nURL=%@\n", [[items objectAtIndex:i] description]];
            NSData *fileData  = [[urlFile dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:NO] retain];
            [fileHandle writeData: fileData];
            [fileHandle release];
            fileHandle = nil;
			

//			NSString *filename = nil;
			FSRef	fileRef;
			OSStatus err;
			HFSUniStr255 theResFileName;
			ResFileRefNum theResFileNum;
			ResFileRefNum saveFileNum = CurResFile();
			const void*	theData = [fileData bytes];
			Handle	theDataHandle;
			
			PtrToHand( theData, &theDataHandle, [fileData length]);
			
			FSGetResourceForkName(&theResFileName);

			filename = [NSString stringWithFormat:@"%@/%@.%@", [dropDestination path], @"PromiseTestFile", @"webloc"];
			err = FSPathMakeRef( (const UInt8*)[filename UTF8String], &fileRef, FALSE );
			NSLog(@"%@ e:%i",filename, (int)err);
			if( err == 0 ) {
				printf("here\n");
				err = FSCreateResourceFork( &fileRef, theResFileName.length, theResFileName.unicode, 0 );
				err = FSOpenResourceFile( &fileRef,  theResFileName.length, theResFileName.unicode, fsWrPerm, &theResFileNum);
				
				if(err == 0) {
					UseResFile( theResFileNum );
					AddResource( theDataHandle, 'url ', 0, (ConstStr255Param)"" );
					err = ResError();
					printf("AddResource: %i\n", (int)err);
					
					UseResFile( saveFileNum );
					CloseResFile( theResFileNum );
				} else 
					 printf("FSOpenResourceFile: %i\n",(int) err);
			
			}
 */
            [filenames addObject: [urlPlace path]];
        }
    
    return ([filenames count] ? filenames : nil);
}

- (BOOL)outlineView:(NSOutlineView *)ov writeItems:(NSArray *)items toPasteboard:(NSPasteboard *)pboard {
	
	draggedNodes = items; // Don't retain since this is just holding temporaral drag information, and it is only used during a drag!  We could put this in the pboard actually.
	
	if( treeDataSource != nil ) return [treeDataSource outlineView:ov writeItems:items toPasteboard:pboard];
	
	draggedNodes = nil;
	return NO;
}
/*	
    draggedNodes = items; // Don't retain since this is just holding temporaral drag information, and it is only used during a drag!  We could put this in the pboard actually.
    
    // Provide data for our custom type, and simple NSStrings.
    //[pboard declareTypes:[NSArray arrayWithObjects:DragDropSimplePboardType, NSStringPboardType, NSFilesPromisePboardType, nil] owner:self];
	[pboard declareTypes:[NSArray arrayWithObjects:DragDropSimplePboardType, NSURLPboardType, nil] owner:self];
    
	// the actual data doesn't matter since DragDropSimplePboardType drags aren't recognized by anyone but us!.
    [pboard setData:[NSData data] forType:DragDropSimplePboardType]; 
    
    // Put string data on the pboard... notice you candrag into TextEdit!
    //[pboard setString: [draggedNodes description] forType: NSStringPboardType];
    
    // Put the promised type we handle on the pasteboard.
    //[pboard setPropertyList:[NSArray arrayWithObjects:@"txt", nil] forType:NSFilesPromisePboardType];

	// Put URL data on the pboard
	[[NSURL URLWithString:[[items objectAtIndex:0] description]] writeToPasteboard:pboard];
	
    return YES;
}
*/

- (NSDragOperation)outlineView:(NSOutlineView *)ov validateDrop:(id <NSDraggingInfo>)info proposedItem:(id)item proposedChildIndex:(NSInteger)childIndex {
    // This method validates whether or not the proposal is a valid one. Returns NO if the drop should not be allowed.
	
	if( treeDataSource != nil ) return [treeDataSource outlineView:ov validateDrop:info proposedItem:item proposedChildIndex:childIndex];
	
	return NSDragOperationNone;
}

/*	
    SimpleTreeNode *targetNode = item;
    BOOL targetNodeIsValid = YES;

    if ([self onlyAcceptDropOnRoot]) {
	targetNode = nil;
	childIndex = NSOutlineViewDropOnItemIndex;
    } else {
	BOOL isOnDropTypeProposal = childIndex==NSOutlineViewDropOnItemIndex;
	
	// Refuse if: dropping "on" the view itself unless we have no data in the view.
	if (targetNode==nil && childIndex==NSOutlineViewDropOnItemIndex && [treeData numberOfChildren]!=0) 
	    targetNodeIsValid = NO;
    
	if (targetNode==nil && childIndex==NSOutlineViewDropOnItemIndex && [self allowOnDropOnLeaf]==NO)
	    targetNodeIsValid = NO;
	
        SimpleTreeNode *node = (item == nil) ? treeData : item;
        SimpleNodeData *data = [node nodeData];

	// Refuse if: we are trying to do something which is not allowed as specified by the UI check boxes.
	if ((targetNodeIsValid && isOnDropTypeProposal==NO && [self allowBetweenDrop]==NO) ||
	    ([data isGroup] && isOnDropTypeProposal==YES && [self allowOnDropOnGroup]==NO) ||
	    ([data isLeaf ] && isOnDropTypeProposal==YES && [self allowOnDropOnLeaf]==NO))
	    targetNodeIsValid = NO;
	    
	// Check to make sure we don't allow a node to be inserted into one of its descendants!
	if (targetNodeIsValid && ([info draggingSource]==outlineView) && [[info draggingPasteboard] availableTypeFromArray:[NSArray arrayWithObject: DragDropSimplePboardType]] != nil) {
	    NSArray *_draggedNodes = [[[info draggingSource] treeDataSource] draggedNodes];
		//SimpleTreeNode *targetParent = (SimpleTreeNode*)[targetNode nodeParent];
	    targetNodeIsValid = ![targetNode isDescendantOfNodeInArray: _draggedNodes];
		if( targetNodeIsValid ) targetNodeIsValid = [targetNode isParentOfNodesInArray: draggedNodes];
	}
    }
    
//	if (targetNodeIsValid && !([info draggingSource]==outlineView)) {
		if( [[targetNode nodeData] itemType] == kPADTypeGroupFavorites ) return NSDragOperationCopy;
		if( [[[targetNode nodeParent] nodeData] itemType] == kPADTypeGroupLibrary ) return NSDragOperationCopy;
		
		targetNodeIsValid = NO;
	}
//
	if (targetNodeIsValid && !([info draggingSource]==outlineView)) {
		if( [[targetNode nodeData] itemType] == kPADTypeGroupFavorites ) return NSDragOperationCopy;
		else if( [[[targetNode nodeParent] nodeData] itemType] == kPADTypeGroupLibrary ) {
			NSArray *_draggedNodes = [[[info draggingSource] treeDataSource] draggedNodes];
			int		nodeIndex, nodeCount = [_draggedNodes count];
			
			for(nodeIndex=0; nodeIndex<nodeCount; nodeIndex++)
				if( [[[[_draggedNodes objectAtIndex:nodeIndex] nodeData] itemFlavor] compare:[[targetNode nodeData] itemFlavor]] != NSOrderedSame )
					return NSDragOperationLink;

			targetNodeIsValid = NO;
		}
		else targetNodeIsValid = NO;
	}
	
    // Set the item and child index in case we computed a retargeted one.
    [outlineView setDropItem:targetNode dropChildIndex:childIndex];
    
    return targetNodeIsValid ? NSDragOperationGeneric : NSDragOperationNone;
}
*/
/*
- (void)_performDropOperation:(id <NSDraggingInfo>)info onNode:(TreeNode *)parentNode atIndex:(NSInteger)childIndex {
    // Helper method to insert dropped data into the model. 
    NSPasteboard *pboard = [info draggingPasteboard];
	
	NSString*	destinationFlavor = [[parentNode nodeData] itemFlavor];
//	CFURLRef	slotURL = NULL;
//	OSStatus	theErr = 0;
    
    if ([pboard availableTypeFromArray:[NSArray arrayWithObjects:DragDropSimplePboardType, nil]] != nil) {
        TreeController *dragDataSource = [[info draggingSource] treeDataSource];
        NSArray *_draggedNodes = [dragDataSource draggedNodes];
        NSEnumerator *draggedNodesEnum = [_draggedNodes objectEnumerator];
        SimpleTreeNode *_draggedNode = nil;
		SimpleTreeNode *_bioParent = nil;
		int				itemRow = 0;
        
        while ((_draggedNode = [draggedNodesEnum nextObject])) {
			

			if( [dragDataSource treeDataSource] != nil ) [[dragDataSource treeDataSource] performSelector:@selector(nodeTypeChanged:toType:) withObject:(SimpleTreeNode*)_draggedNode withObject:destinationFlavor];

			[[dragDataSource outlineView] reloadItem:_draggedNode];
			
//			_bioParent = (SimpleTreeNode*)[_draggedNode nodeParent];
//			itemRow = [_bioParent indexOfChild:_draggedNode];
//			[_draggedNode removeFromParent];
//			[[dragDataSource outlineView] reloadItem:_bioParent];
//			[_bioParent insertChild:_draggedNode atIndex:itemRow];
//			[[dragDataSource outlineView] reloadItem:_bioParent];
		}
		[[dragDataSource outlineView] reloadData];
	}
}
 */
 
//			if( slotURL ) {
//				theErr = CFURLSetXattr( slotURL, kDACALCarouselDocumentXAttrSlotKind, (CFStringRef)destinationFlavor );
//			
//				[[_draggedNode nodeData] setItemFlavor:destinationFlavor];
//				[[dragDataSource outlineView] reloadItem:_draggedNode];
//			}
//		}
//		[[dragDataSource treeDataSource] sortExpandedChildrenWithCurrentDescriptors:nil];
		
//	}
/*
	// Do the appropriate thing depending on wether the data is DragDropSimplePboardType or NSStringPboardType.
    if ([pboard availableTypeFromArray:[NSArray arrayWithObjects:DragDropSimplePboardType, nil]] != nil) {
        TreeController *dragDataSource = [[info draggingSource] treeDataSource];
        NSArray *_draggedNodes = [TreeNode minimumNodeCoverFromNodesInArray:[dragDataSource draggedNodes]];
        NSEnumerator *draggedNodesEnum = [_draggedNodes objectEnumerator];
        SimpleTreeNode *_draggedNode = nil, *_draggedNodeParent = nil;
        
	itemsToSelect = [NSMutableArray arrayWithArray:[self selectedNodes]];
	
        while ((_draggedNode = [draggedNodesEnum nextObject])) {
            _draggedNodeParent = (SimpleTreeNode *)[_draggedNode nodeParent];
            if (parentNode == _draggedNodeParent && [parentNode indexOfChild:_draggedNode] < childIndex) childIndex--;
            [_draggedNodeParent removeChild:_draggedNode];
        }
        [parentNode insertChildren:_draggedNodes atIndex:childIndex];
    }  else if ([pboard availableTypeFromArray:[NSArray arrayWithObject:NSStringPboardType]]) {
        NSString *string = [pboard stringForType:NSStringPboardType];
	SimpleTreeNode *newItem = [SimpleTreeNode treeNodeWithData:[SimpleNodeData leafDataWithName:string]];
	
	itemsToSelect = [NSMutableArray arrayWithObject:newItem];
	[parentNode insertChild:newItem atIndex:childIndex++];
    }
*/
//    [outlineView reloadData];
//    [outlineView selectItems:itemsToSelect byExtendingSelection: NO];
//}

- (BOOL)outlineView:(NSOutlineView *)ov acceptDrop:(id <NSDraggingInfo>)info item:(id)item childIndex:(NSInteger)childIndex {

	if( treeDataSource != nil ) return [treeDataSource outlineView:ov acceptDrop:info item:item childIndex:childIndex];
	
    return YES;
}
/*
	SimpleTreeNode *node = item;
    SimpleNodeData *data = [node nodeData];
    
    if ([data isLeaf]) {
		if( [[[node nodeParent] nodeData] itemType] == kPADTypeGroupLibrary ) {
			
		    [self _performDropOperation:info onNode:node atIndex:childIndex];	
			
		}
		
		
	}
		
	if( [data itemType] == kPADTypeGroupDevices ) {
//		SimpleTreeNode *parent = (SimpleTreeNode*)[item nodeParent];
		DACALDeviceRef boxRef;
		DACALResult theErr = 0;
	    NSObject *entry = nil;
		NSEnumerator *enumerator = [[item children] objectEnumerator];
		while ((entry=[enumerator nextObject])) {
			boxRef = [[(SimpleTreeNode *)entry nodeData] itemDevice];
			// if( boxRef ) theErr= DACALCommandSetNode( boxRef, [item indexOfChildIdenticalTo:(TreeNode*)entry]+1 );
			NSLog( @"DACALCommandSetNode( %@, %i ): %i", (NSURL*)boxRef, [item indexOfChildIdenticalTo:(TreeNode*)entry]+1, theErr );
		}
    }
 }
*/
        
- (void)draggedImage:(NSImage *)image endedAt:(NSPoint)screenPoint operation:(NSDragOperation)operation
{
	if( treeDataSource ) [treeDataSource draggedImage:image endedAt:screenPoint operation:operation];
}

// On MacOS 10.5 and above, NSTableView and NSOutlineView have better contextual menu support. We now see a highlighted item for what was clicked on,
// and can access that item to do particular things (such as dynamically change the menu, as we do here!). Each of the contextual menus in the nib file
// have the delegate set to be the AppController instance. In menuNeedsUpdate, we dynamically update the menus based on the currently clicked upon row/column pair.
- (void)menuNeedsUpdate:(NSMenu *)menu {
	// Tell data source
	if( treeDataSource != nil ) [treeDataSource performSelector:@selector(menuNeedsUpdate:fromTree:) withObject:menu withObject:self];
}

- (IBAction)expandableMenuItemAction:(id)sender {
    // The tag of the clicked row contains the item that was clicked on
    NSInteger clickedRow = [outlineView clickedRow];
    id item = [outlineView itemAtRow:clickedRow];
    SimpleNodeData *nodeData = [item nodeData];
    // Flip the expandable state,
    [nodeData setExpandable:![nodeData isExpandable]];
    // Refresh that row (since its state has changed)
    [outlineView setNeedsDisplayInRect:[outlineView rectOfRow:clickedRow]];
    // And collopse it if we can no longer expand it 
    if (![nodeData isExpandable] && [outlineView isItemExpanded:item]) [outlineView collapseItem:item];
}

@end	// TreeController

@implementation TreeController(Private)

- (void)_addNewDataToSelection:(SimpleTreeNode *)newChild {
    NSInteger childIndex = 0, newRow = 0;
    NSArray *selectedNodes = [self selectedNodes];
    SimpleTreeNode *selectedNode = ([selectedNodes count]>0) ? [selectedNodes objectAtIndex:0] : treeData;
    TreeNode *parentNode = nil;

    if ([[selectedNode nodeData] isGroup]) { 
	parentNode = selectedNode; 
	childIndex = 0; 
    }
    else { 
	parentNode = [selectedNode nodeParent]; 
	childIndex = [parentNode indexOfChildIdenticalTo:selectedNode]+1; 
    }
    
    [parentNode insertChild: newChild atIndex: childIndex];
    [outlineView reloadData];
    
    newRow = [outlineView rowForItem: newChild];
    if (newRow>=0) [outlineView selectRow: newRow byExtendingSelection: NO];
    if (newRow>=0) [outlineView editColumn:0 row:newRow withEvent:nil select:YES];
}

@end	// TreeController(Private)

@implementation TreeControllerDataSource

- (id)treeControl { return treeControl; }
- (void)setTreeControl:(id)tree
{
	if( treeControl != nil ) [treeControl release];
	if( tree != nil ) [tree retain];
	treeControl = tree;
}

- (NSOutlineView*)outlineView
{
	if( [self treeControl] ) 
		return [[self treeControl] outlineView];
	
	return nil;
}

//	Returns the NSUndoManager for the tree outline view
- (NSUndoManager*)undoManager
{
	NSOutlineView*		ourView = [self outlineView];
	
	if( ourView )
		return [ourView undoManager];
	
	return nil; 
}

- (void)removeAllChildren
{
	[[[[self treeControl] treeRoot] children] makeObjectsPerformSelector:@selector(removeFromParent)];
	[[[self treeControl] outlineView] reloadData];
}

- (PADIndexToolbarController *)toolbarControl {
	return toolbarControl;
}

- (void)setToolbarControl: (id) tbar {
	if (toolbarControl != nil)
		[toolbarControl release];
	if (tbar != nil)
		[tbar retain];
	toolbarControl = tbar;
}

- (SimpleTreeNode*)createInitialTree:(id)tree
{
	SimpleTreeNode*		theOutputTree = nil;

	if( [self treeControl] == nil ) [self setTreeControl:tree];

	// Load our initial outline view data from the "InitInfo" dictionary.
	NSDictionary *initData = [NSDictionary dictionaryWithContentsOfFile: [[NSBundle mainBundle] pathForResource:@"InitInfo" ofType: @"dict"]];
	if( initData != nil ) theOutputTree = [SimpleTreeNode treeFromDictionary: initData];	
	
	return theOutputTree;
}

- (void)outlineViewInit
{
	NSOutlineView* outlineView = [[self treeControl] outlineView];
	
    // Register to get our custom type, strings, and filenames. Try dragging each into the view!
    [outlineView registerForDraggedTypes:[NSArray arrayWithObjects:DragDropSimplePboardType, NSStringPboardType, NSFilenamesPboardType, nil]];
    [outlineView setDraggingSourceOperationMask:NSDragOperationEvery forLocal:YES];
    [outlineView setDraggingSourceOperationMask:NSDragOperationEvery forLocal:NO];
    //[outlineView setAutoresizesOutlineColumn:NO];
}

- (void)reinitOutlineView
{
	
}

- (void)recreateInitialTree
{	
	// Install Data for Tree
	[[self treeControl] setTreeRoot:[self createInitialTree:[self treeControl]]];
	
	// Initialize the View
	[self reinitOutlineView];
	
	// Refresh
	[[self outlineView] reloadData];
	
}

- (void)outlineViewAction:(id)tree
{
/*   NSArray *selectedNodes = [treeControl selectedNodes];
    
    if ([selectedNodes count] > 1) {
        [selectionOutput setStringValue: @"Multiple Rows Selected"];
    } else if ([selectedNodes count] == 1) {
        SimpleNodeData *data = [[selectedNodes objectAtIndex:0] nodeData];
        [selectionOutput setStringValue:[data description]];  
    } else {
        [selectionOutput setStringValue: @"Nothing Selected"];   
    }
*/
}

- (void)outlineViewDoubleAction:(id)tree
{
//	NSArray	*selectedNodes = [treeControl selectedNodes];
//	NSInteger	indexCount = [[treeControl outlineView] clickedColumn];
//	NSInteger	nodeCount = [selectedNodes count];
	NSOutlineView	*theView	= [treeControl outlineView];
	NSInteger		rowIndex	= [theView clickedRow];
	NSInteger		colIndex	= [theView clickedColumn];
	NSInteger		partHit		= NSCellHitNone;
	NSRect			rowFrame	= [theView frameOfCellAtColumn:0 row:rowIndex];
	SimpleTreeNode	*workNode	= nil;
	NSCell			*workCell	= nil;
	
	//if( [[treeControl outlineView] clickedColumn] != -1 ) return;
	
	if( rowIndex == -1 ) return;		//  That is a double-click in a blank row.
	
	if( colIndex == [theView columnWithIdentifier:COLUMNID_NAME] ) {
		workNode = [theView itemAtRow:rowIndex];
		workCell = [theView preparedCellAtColumn:colIndex row:rowIndex];		

		partHit = [workCell hitTestForEvent:[[NSApplication sharedApplication]currentEvent] inRect:rowFrame ofView:theView];
		
		if( partHit == NSCellHitIconArea ) {
			if( [self respondsToSelector:@selector(doubleClickImage:inCell:)] == YES )
				[self performSelector:@selector(doubleClickImage:inCell:) withObject:(id)workNode withObject:workCell];
		} else if( [self respondsToSelector:@selector(doubleClickCellContent:inCell:)] == YES )
            [self performSelector:@selector(doubleClickCellContent:inCell:) withObject:(id)workNode withObject:workCell];
        else if([[workNode nodeData] isExpandable] == YES ) {
            if( [theView isItemExpanded:workNode] == YES ) {
                [theView collapseItem:workNode];
            } else {
                [theView expandItem:workNode];
            }
        }
	} else if( colIndex != -1 )	{
		workNode = [theView itemAtRow:rowIndex];
		workCell = [theView preparedCellAtColumn:colIndex row:rowIndex];
		if( [self respondsToSelector:@selector(doubleClickCellContent:inCell:)] == YES )
			[self performSelector:@selector(doubleClickCellContent:inCell:) withObject:(id)workNode withObject:workCell];
		else if([[workNode nodeData] isExpandable] == YES ) {
			if( [theView isItemExpanded:workNode] == YES ) {
				[theView collapseItem:workNode];
			} else {
				[theView expandItem:workNode];
			}
        }
	}
	return;
}


-(id)objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
    id objectValue = nil;
 
    if ((tableColumn == nil) || [[tableColumn identifier] isEqualToString:COLUMNID_NAME]) {
		objectValue = [[item nodeData] name];
   } else
		NSLog(@"Data Request for Unknown Column: %@", [tableColumn identifier]);
	
	return objectValue;
}

-(void)setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
	SimpleTreeNode*	actual = [item matchActual];

    // Here, we manipulate the name data stored in the node.
    if ((tableColumn == nil) || [[tableColumn identifier] isEqualToString:COLUMNID_NAME]) {
		[self nodeNameChanged:actual toName:object];
		return;
	}

	NSLog(@"Data Change for Unknown Column: %@", [tableColumn identifier]);
}

// To get the "group row" look, we implement this method.
- (BOOL)outlineView:ov isGroupItem:(id)item {
    return [[item nodeData] isGroup] && [[self treeControl] allowGroupRowLook];
}

- (BOOL)outlineView:(NSOutlineView *)ov shouldExpandItem:(id)item {
    return [[item nodeData] isGroup];
}

- (BOOL)outlineView:(NSOutlineView *)ov shouldCollapseItem:(id)item {
    return [[item nodeData] isGroup];
}

- (BOOL)outlineView:(NSOutlineView *)ov shouldSelectItem:(id)item {
    // Control selection of a particular item. 
	BOOL result = [[item nodeData] isSelectable];
    return result;
}

- (BOOL)performDropOperation:(id <NSDraggingInfo>)info onNode:(TreeNode *)parentNode atIndex:(NSInteger)childIndex
{
    // Helper method to insert dropped data into the model. 
    NSPasteboard *pboard = [info draggingPasteboard];
	NSMutableArray* itemsToSelect = nil;
	
	// Do the appropriate thing depending on wether the data is DragDropSimplePboardType or NSStringPboardType.
    if ([pboard availableTypeFromArray:[NSArray arrayWithObjects:DragDropSimplePboardType, nil]] != nil) {
        TreeController *dragDataSource = [[info draggingSource] treeDataSource];
        NSArray *_draggedNodes = [TreeNode minimumNodeCoverFromNodesInArray:[dragDataSource draggedNodes]];
        NSEnumerator *draggedNodesEnum = [_draggedNodes objectEnumerator];
        SimpleTreeNode *_draggedNode = nil, *_draggedNodeParent = nil;
        
		itemsToSelect = [NSMutableArray arrayWithArray:[treeControl selectedNodes]];
		
        while ((_draggedNode = [draggedNodesEnum nextObject])) {
            _draggedNodeParent = (SimpleTreeNode *)[_draggedNode nodeParent];
            if (parentNode == _draggedNodeParent && [parentNode indexOfChild:_draggedNode] < childIndex) childIndex--;
            [_draggedNodeParent removeChild:_draggedNode];
        }
        [parentNode insertChildren:_draggedNodes atIndex:childIndex];
    }  else if ([pboard availableTypeFromArray:[NSArray arrayWithObject:NSStringPboardType]]) {
        NSString *string = [pboard stringForType:NSStringPboardType];
		SimpleTreeNode *newItem = [SimpleTreeNode treeNodeWithData:[SimpleNodeData leafDataWithName:string]];
		
		itemsToSelect = [NSMutableArray arrayWithObject:newItem];
		[parentNode insertChild:newItem atIndex:childIndex++];
    }
	
	[[treeControl outlineView] reloadData];
	[[treeControl outlineView] selectItems:itemsToSelect byExtendingSelection: NO];
	
	return (itemsToSelect!=nil) ? YES : NO;
}

- (BOOL)outlineView:(NSOutlineView *)ov writeItems:(NSArray *)items toPasteboard:(NSPasteboard *)pboard {
	
    // Provide data for our custom type, and simple NSStrings.
    //[pboard declareTypes:[NSArray arrayWithObjects:DragDropSimplePboardType, NSStringPboardType, NSFilesPromisePboardType, nil] owner:self];
	[pboard declareTypes:[NSArray arrayWithObjects:DragDropSimplePboardType, NSURLPboardType, nil] owner:self];
    
	// the actual data doesn't matter since DragDropSimplePboardType drags aren't recognized by anyone but us!.
    [pboard setData:[NSData data] forType:DragDropSimplePboardType]; 
    
    // Put string data on the pboard... notice you candrag into TextEdit!
    //[pboard setString: [draggedNodes description] forType: NSStringPboardType];
    
    // Put the promised type we handle on the pasteboard.
    //[pboard setPropertyList:[NSArray arrayWithObjects:@"txt", nil] forType:NSFilesPromisePboardType];
	
	// Put URL data on the pboard
	if( items && ([items count]>0) )
		[[NSURL URLWithString:[[items objectAtIndex:0] description]] writeToPasteboard:pboard];
	
    return YES;
}

- (NSDragOperation)validateDropSource:(id <NSDraggingInfo>)info proposedItem:(id)item proposedChildIndex:(NSInteger)childIndex
{

	return NSDragOperationGeneric;
}

- (NSDragOperation)outlineView:(NSOutlineView *)ov validateDrop:(id <NSDraggingInfo>)info proposedItem:(id)item proposedChildIndex:(NSInteger)childIndex {
    SimpleTreeNode *targetNode = item;
    BOOL targetNodeIsValid = YES;
	NSDragOperation targetNodeDragOp = NSDragOperationNone;
	
    if ([treeControl onlyAcceptDropOnRoot]) {
		targetNode = nil;
		childIndex = NSOutlineViewDropOnItemIndex;
    } else {
		BOOL isOnDropTypeProposal = childIndex==NSOutlineViewDropOnItemIndex;
		
		// Refuse if: dropping "on" the view itself unless we have no data in the view.
		if (targetNode==nil && childIndex==NSOutlineViewDropOnItemIndex && [[treeControl treeRoot] numberOfChildren]!=0) 
			targetNodeIsValid = NO;
		
		if (targetNode==nil && childIndex==NSOutlineViewDropOnItemIndex && [treeControl allowOnDropOnLeaf]==NO)
			targetNodeIsValid = NO;
		
        SimpleTreeNode *node = (item == nil) ? [treeControl treeRoot] : item;
        SimpleNodeData *data = [node nodeData];
		
		// Refuse if: we are trying to do something which is not allowed as specified by the UI check boxes.
		if ((targetNodeIsValid && isOnDropTypeProposal==NO && [treeControl allowBetweenDrop]==NO) ||
			([data isGroup] && isOnDropTypeProposal==YES && [treeControl allowOnDropOnGroup]==NO) ||
			([data isLeaf ] && isOnDropTypeProposal==YES && [treeControl allowOnDropOnLeaf]==NO))
			targetNodeIsValid = NO;
	    
		// Check to make sure we don't allow a node to be inserted into one of its descendants!
		if (targetNodeIsValid && ([info draggingSource]==[treeControl outlineView]) && [[info draggingPasteboard] availableTypeFromArray:[NSArray arrayWithObject: DragDropSimplePboardType]] != nil) {
			NSArray *_draggedNodes = [[[info draggingSource] treeDataSource] draggedNodes];
			//SimpleTreeNode *targetParent = (SimpleTreeNode*)[targetNode nodeParent];
			targetNodeIsValid = ![targetNode isDescendantOfNodeInArray: _draggedNodes];
			//if( targetNodeIsValid ) targetNodeIsValid = [targetNode isParentOfNodesInArray: [treeControl draggedNodes]];
		}
    }
    
	if( targetNodeIsValid )
		targetNodeDragOp = [self validateDropSource:info proposedItem:item proposedChildIndex:childIndex];
	
    // Set the item and child index in case we computed a retargeted one.
    [[treeControl outlineView] setDropItem:targetNode dropChildIndex:childIndex];
    
    return targetNodeIsValid ? targetNodeDragOp : NSDragOperationNone;
}

- (BOOL)outlineView:(NSOutlineView *)ov acceptDrop:(id <NSDraggingInfo>)info item:(id)item childIndex:(NSInteger)childIndex
{
	
    // Determine the parent to insert into and the child index to insert at.
    SimpleTreeNode *node = (item == nil) ? [treeControl treeRoot] : item;
    SimpleNodeData *data = [node nodeData];
    
    if ([data isLeaf]) {
        // If our target is a leaf, and we are dropping on it
        if (childIndex == NSOutlineViewDropOnItemIndex) {
            // If we are dropping on a leaf, we will have to turn it into a non-leaf node, and insert it at the start
            [data setIsLeaf:NO];
            [data setExpandable:YES];
            childIndex = 0;
        } else {
            // We will be dropping on the item's parent at the target index of this child, plus one
            childIndex = [[node nodeParent]indexOfChild:node] + 1;
            node = (SimpleTreeNode *)[node nodeParent];
        }
    } else {            
        if (childIndex == NSOutlineViewDropOnItemIndex) {
            // Insert it at the start, if we were dropping on it
            childIndex = 0;
        }
    }
    
    return [self performDropOperation:info onNode:node atIndex:childIndex];	
}


// In order to support drags to the trash, you need to implement draggedImage:endedAt:operation: and handle the NSDragOperationDelete operation.  
// For any other operation, pass the message to the superclass
- (void)draggedImage:(NSImage *)image endedAt:(NSPoint)screenPoint operation:(NSDragOperation)op
{
	if (op == NSDragOperationDelete) {
        // Tell all of the dragged nodes to remove themselves from the model.
        NSArray *selection = [[self treeControl] draggedNodes];
        [selection makeObjectsPerformSelector: @selector(removeFromParent)];
        [[self outlineView] deselectAll:nil];
        [[self outlineView] reloadData];
	}
	
	//[super draggedImage:image endedAt:screenPoint operation:op];
}

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem {

	//NSLog(@"Validate Menu Item: %@", [menuItem title]);
	
    if ([menuItem action]==@selector(deleteSelections:)) {
		// The delete selection item should be disabled if nothing is selected.
		return ([[[self treeControl] selectedNodes] count] > 0);
    }    
	
    return YES;
}

- (NSArray*)ctmClickedRows
{
	NSArray*		outRowArray = nil;
	NSOutlineView*	outlineView = [ treeControl outlineView ];
    NSInteger		clickedRow = [outlineView clickedRow];
    id				item = nil;
    BOOL			clickedOnMultipleItems = NO;
	
    if (clickedRow != -1) {
        // If we clicked on a selected row, then we want to consider all rows in the selection. Otherwise, we only consider the clicked on row.
        item = [outlineView itemAtRow:clickedRow];
        clickedOnMultipleItems = [outlineView isRowSelected:clickedRow] && ([outlineView numberOfSelectedRows] > 1);
    }
    
	if( clickedOnMultipleItems )
		outRowArray = [outlineView allSelectedItems];
	else
		outRowArray = [NSArray arrayWithObject:item];

	return outRowArray;
}

// On MacOS 10.5 and above, NSTableView and NSOutlineView have better contextual menu support. We now see a highlighted item for what was clicked on, and can access that item to do particular things (such as dynamically change the menu, as we do here!). Each of the contextual menus in the nib file have the delegate set to be the AppController instance. In menuNeedsUpdate, we dynamically update the menus based on the currently clicked upon row/column pair.
- (void)menuNeedsUpdate:(NSMenu *)menu {
	
	NSOutlineView* outlineView = [ treeControl outlineView ];
    NSInteger clickedRow = [outlineView clickedRow];
    id item = nil;
    SimpleNodeData *nodeData = nil;
    BOOL clickedOnMultipleItems = NO;

    if (clickedRow != -1) {
        // If we clicked on a selected row, then we want to consider all rows in the selection. Otherwise, we only consider the clicked on row.
        item = [outlineView itemAtRow:clickedRow];
        nodeData = [item nodeData];
        clickedOnMultipleItems = [outlineView isRowSelected:clickedRow] && ([outlineView numberOfSelectedRows] > 1);
    }
    
    if (menu == outlineViewContextMenu) {
        NSMenuItem *menuItem = [menu itemAtIndex:0];
        if (nodeData != nil) {
            if (clickedOnMultipleItems) {
                // We could walk through the selection and note what was clicked on at this point
                [menuItem setTitle:[NSString stringWithFormat:@"You clicked on %ld items!", (long)[outlineView numberOfSelectedRows]]];
            } else {
                [menuItem setTitle:[NSString stringWithFormat:@"You clicked on: '%@'", [nodeData name]]];
            }
            [menuItem setEnabled:YES];
        } else {
            [menuItem setTitle:@"You didn't click on any rows..."];
            [menuItem setEnabled:NO];
        }
        
    }
	
/*	else if (menu == expandableColumnMenu) {
        NSMenuItem *menuItem = [menu itemAtIndex:0];
        if (!clickedOnMultipleItems && (nodeData != nil)) {
            // The item will be enabled only if it is a group
            [menuItem setEnabled:[nodeData isGroup]];
            // Check it if it is expandable
            [menuItem setState:[nodeData isExpandable] ? 1 : 0];
        } else {
            [menuItem setEnabled:NO];
        }
    }
*/
}

- (void)menuNeedsUpdate:(NSMenu *)menu fromTree:(id)tree
{
	return [self menuNeedsUpdate:menu];
}

- (void)nodeNameChanged:(SimpleTreeNode*)theNode toName:(NSString*)theName
{
	SimpleNodeData*	theData = [theNode nodeData];
	[theData setName:theName];
	return;
}

- (void)nodeDidCollapse:(SimpleTreeNode*)theNode
{
	return;
}

- (void)nodeDidExpand:(SimpleTreeNode*)theNode
{
	return;
}

- (void)selectionDidChange
{
	return;
}

- (NSInteger)shouldEditTableColumn:(NSTableColumn *)tc item:(id)item
{
	return YES;
}

- (NSInteger)shouldSelectColumn:(NSTableColumn *)tc
{
	return NO;
}

- (void)sortExpandedChildrenWithCurrentDescriptors:(SimpleTreeNode*)theNode
{
	if( theNode == nil )
        theNode = [[self treeControl] treeRoot];
	if( theNode )
        [theNode sortExpandedChildrenUsingDescriptors:[[[self treeControl] outlineView] sortDescriptors ]];
}

- (BOOL)shouldShowCellExpansionForTableColumn:(NSTableColumn *)tc item:(id)inItem
{
	return NO;
}

- (NSString*)toolTipForCell:(NSCell *)cell rect:(NSRectPointer)inRect tableColumn:(NSTableColumn *)tc item:(id)inItem mouseLocation:(NSPoint)inMouseLocation
{
	return [inItem tooltip];
}

- (void)updateChangesForItem:(id)changeItem withAction:(BOOL)doAction
{
	[self sortExpandedChildrenWithCurrentDescriptors:changeItem];
	[[self outlineView] reloadData];
	if( doAction == YES )
		[self outlineViewAction:self];
	
	return;
	
	SimpleTreeNode*		itemParent = nil; //(SimpleTreeNode*)[changeItem nodeParent];
	
	if( itemParent == nil )
		itemParent = [[self treeControl] treeRoot];
	
	[self sortExpandedChildrenWithCurrentDescriptors:itemParent];
	[[self outlineView] reloadItem:(id)itemParent reloadChildren:YES];
	[[self outlineView] reloadItem:(id)changeItem reloadChildren:YES];
	
	if( doAction == YES )
		[self outlineViewAction:self];
}

- (void)updateChangesForItems:(NSArray*)changedItems withAction:(BOOL)doAction
{
	NSInteger	itemIndex, itemCount = [changedItems count];
	NSArray*	saveSelection = [[self outlineView] allSelectedItems];
	
	if( itemCount == 0 )
		[self updateChangesForItem:nil withAction:NO];
	else
		for( itemIndex=0; itemIndex < itemCount; itemIndex++ )
			[self updateChangesForItem:[changedItems objectAtIndex:itemIndex] withAction:NO];
	
	if( saveSelection )
		[[self outlineView] selectItems:saveSelection byExtendingSelection:NO];
	
	if( doAction == YES )
		[self outlineViewAction:self];
}

- (void)updateChangesWithAction:(BOOL)doAction
{ [self updateChangesForItem:nil withAction:doAction]; }

- (void)dealloc {
	[treeControl release];
	[toolbarControl release];
	[super dealloc];
}

@end	// TreeControllerDataSource

