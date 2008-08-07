//
//  TreeController.m
//  DragNDropOutlineView
//
//  Created by Jack Small on 7/4/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "TreeController.h"

#import <CoreFoundation/CoreFoundation.h>

@interface TreeController(Private)
- (void)_addNewDataToSelection:(SimpleTreeNode *)newChild;
@end

// ================================================================
// Useful Macros
// ================================================================

#define DragDropSimplePboardType 	@"MyCustomOutlineViewPboardType"


@implementation TreeController

- (id)init {
    if (self = [super init]) {
		
	}

    return self; 
}

- (void)dealloc {
    [treeData release];
    [draggedNodes release];
    [super dealloc];
}


- (void)awakeFromNib {

	// Install Data for Tree
	if( dataSource != nil ) [self setTreeRoot:[dataSource performSelector:@selector(createInitialTree:) withObject:self]];

	// Initialize the View
	if( dataSource != nil ) [dataSource performSelector:@selector(outlineViewInit)];
	
	// Setup doubles
	[[self outlineView] setDoubleAction:@selector(outlineViewDoubleAction:)];
	
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

- (SimpleTreeNode*)treeRoot { return treeData; }
	
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
		[self setTreeRoot:newChild];
		return;
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
    [outlineView reloadData];
}

- (id)dataSource { return dataSource; }

- (NSOutlineView*)outlineView { return outlineView; }
- (void)setOutlineView:(NSOutlineView*)view
{
	if( outlineView != nil ) [outlineView release];
	if( view != nil ) [view retain];
	outlineView = view;
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
	if( dataSource != nil ) [dataSource performSelector:@selector(outlineViewAction:) withObject:self];

}

- (void)outlineViewDoubleAction:(id)olv {
	// This message is sent from th outlineView as it's double-action (see awakeFromNib)

	// Tell data source
	if( dataSource != nil ) [dataSource performSelector:@selector(outlineViewDoubleAction:) withObject:self];
}

- (void)deleteSelections:(id)sender {
    NSArray *selection = [self selectedNodes];
    
    // Tell all of the selected nodes to remove themselves from the model.
    [selection makeObjectsPerformSelector: @selector(removeFromParent)];
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
    return [[node nodeData] isGroup];
}

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item {
    SimpleTreeNode *node = (item == nil) ? treeData : item;
    return [node numberOfChildren];
}

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item {
    id objectValue = nil;
    SimpleNodeData *data = [item nodeData];
    
    // The return value from this method is used to configure the state of the items cell via setObjectValue:
    if ((tableColumn == nil) || [[tableColumn identifier] isEqualToString:COLUMNID_NAME]) {
		objectValue = [data name];
		[item setBusy: [data busy]];
    } else if ([[tableColumn identifier] isEqualToString:COLUMNID_SLOT]) {
		objectValue = [NSString stringWithFormat:@"%i", [data itemSlot]];
	}
/*  
 *	These are additional column data suppliers from the original example:
 *
    } else if ([[tableColumn identifier] isEqualToString:COLUMNID_IS_EXPANDABLE]) {
	// Here, object value will be used to set the state of a check box.
	objectValue = [NSNumber numberWithBool:[data isGroup] && [data isExpandable]];
    } else if ([[tableColumn identifier] isEqualToString:COLUMNID_NODE_KIND]) {
	objectValue = ([data isLeaf] ? @"Leaf" : @"Group");
    } else if ([[tableColumn identifier] isEqualToString:COLUMID_IS_SELECTABLE]) {
        // Again -- this object value will set the state of the check box.
        objectValue = [NSNumber numberWithBool:[data isSelectable]];
    }
*/
    return objectValue;
}


// Optional method: needed to allow editing.
- (void)outlineView:(NSOutlineView *)ov setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn byItem:(id)item  {
    SimpleNodeData *data = [item nodeData];
    
    // Here, we manipulate the name data stored in the node.
    if ((tableColumn == nil) || [[tableColumn identifier] isEqualToString:COLUMNID_NAME]) {
		if( dataSource != nil ) [dataSource performSelector:@selector(nodeNameChanged:toName:) withObject:(SimpleTreeNode*)item withObject:(NSString*)object];
		else [data setName:object];
	}

    // Here, we manipulate the slot data stored in the node.
    if ((tableColumn == nil) || [[tableColumn identifier] isEqualToString:COLUMNID_SLOT]) {
		if( dataSource != nil ) [dataSource performSelector:@selector(nodeSlotChanged:toSlot:) withObject:(SimpleTreeNode*)item withObject:(NSString*)object];
		else [data setItemSlot:(DACALSlotNum)[object intValue]];
	}
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
        if ([[item nodeData] isGroup]) {
            // We want to use the cell for the name column, but we could construct a new cell if we wanted to, or return a different cell for each row.
            return [[outlineView tableColumnWithIdentifier:COLUMNID_NAME] dataCell];
        }
    }
	
	// If the item is a new cell, startup busy if necessary
	if ((tableColumn == nil) || [[tableColumn identifier] isEqualToString:COLUMNID_NAME])
		[outCell setBusy: [item busy]];
	
    return outCell;
}

// To get the "group row" look, we implement this method.
- (BOOL)outlineView:ov isGroupItem:(id)item {
    return [[item nodeData] isGroup] && [self allowGroupRowLook];
}

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldExpandItem:(id)item {
    return [[item nodeData] isExpandable];
}

- (void)outlineView:(NSOutlineView *)outlineView willDisplayCell:(NSCell *)cell forTableColumn:(NSTableColumn *)tableColumn item:(id)item {    
    SimpleNodeData *data = [item nodeData];
    if ((tableColumn == nil) || [[tableColumn identifier] isEqualToString:COLUMNID_NAME]) {

	// Make sure the image and text cell has an image.  If not, give it something random.
	//if (![data iconRep]) [data setIconRep:[self _randomIconImage]];
        // We know that the cell at this column is our image and text cell, so grab it
        ImageAndTextCell *imageAndTextCell = (ImageAndTextCell *)cell;
	// Set the image here since the value returned from outlineView:objectValueForTableColumn:... didn't specify the image part...
	if ([data iconRep]) [imageAndTextCell setImage:[data iconRep]];
	else [imageAndTextCell setImage:nil];
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
	if( dataSource != nil )
		if( [dataSource performSelector:@selector(shouldEditTableColumn:item:) withObject:tc withObject:item] == 0 ) return NO;
	return YES;
}

- (BOOL)outlineView:(NSTableView *)outView shouldSelectTableColumn:(NSTableColumn *)tc
{
	if( dataSource != nil )
		if( [dataSource performSelector:@selector(shouldSelectColumn:) withObject:tc] == 0 ) return NO;
	return YES;
}

- (BOOL)outlineView:(NSOutlineView *)ov shouldSelectItem:(id)item {
    // Control selection of a particular item. 
    BOOL result = [[item nodeData] isSelectable];
    if (result) {
        //We can access the clicked row and column to potentially disable row selection based on what item was clicked on. We don't want to change the selection when clicking on a column with a button cell, if that option is checked.
        if (![self allowButtonCellsToChangeSelection]) {
            NSInteger clickedCol = [ov clickedColumn];
            NSInteger clickedRow = [ov clickedRow];
            if (clickedRow >= 0 && clickedCol >= 0) {
                NSCell *cell = [ov preparedCellAtColumn:clickedCol row:clickedRow];
                if ([cell isKindOfClass:[NSButtonCell class]] && [cell isEnabled]) {
                    result = NO;
                }            
            }
        }
    }
    return result;
}

- (BOOL)outlineView:(NSOutlineView *)ov shouldTrackCell:(NSCell *)cell forTableColumn:(NSTableColumn *)tableColumn item:(id)item {
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

// We promised the files, so now lets make good on that promise!
- (NSArray *)outlineView:(NSOutlineView *)outlineView namesOfPromisedFilesDroppedAtDestination:(NSURL *)dropDestination forDraggedItems:(NSArray *)items {
    NSInteger i = 0, count = [items count];
    NSMutableArray *filenames = [NSMutableArray array];
    for (i=0; i<count; i++) {
        
        NSString *filename  = nil;
        NSFileHandle *fileHandle = NewFileHandleForWritingFile([dropDestination path], @"PromiseTestFile", @"txt", &filename);
        if (fileHandle) {
            NSData *fileData  = [[[items objectAtIndex:i] description] dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:NO];
            [fileHandle writeData: fileData];
            [fileHandle release];
            fileHandle = nil;

            [filenames addObject: filename];
        }
    }
    return ([filenames count] ? filenames : nil);
}

- (BOOL)outlineView:(NSOutlineView *)outlineView writeItems:(NSArray *)items toPasteboard:(NSPasteboard *)pboard {
    draggedNodes = items; // Don't retain since this is just holding temporaral drag information, and it is only used during a drag!  We could put this in the pboard actually.
    
    // Provide data for our custom type, and simple NSStrings.
    [pboard declareTypes:[NSArray arrayWithObjects:DragDropSimplePboardType, NSStringPboardType, NSFilesPromisePboardType, nil] owner:self];

    // the actual data doesn't matter since DragDropSimplePboardType drags aren't recognized by anyone but us!.
    [pboard setData:[NSData data] forType:DragDropSimplePboardType]; 
    
    // Put string data on the pboard... notice you candrag into TextEdit!
    [pboard setString: [draggedNodes description] forType: NSStringPboardType];
    
    // Put the promised type we handle on the pasteboard.
    [pboard setPropertyList:[NSArray arrayWithObjects:@"txt", nil] forType:NSFilesPromisePboardType];

    return YES;
}

- (NSDragOperation)outlineView:(NSOutlineView *)ov validateDrop:(id <NSDraggingInfo>)info proposedItem:(id)item proposedChildIndex:(NSInteger)childIndex {
    // This method validates whether or not the proposal is a valid one. Returns NO if the drop should not be allowed.
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
	    NSArray *_draggedNodes = [[[info draggingSource] dataSource] draggedNodes];
		//SimpleTreeNode *targetParent = (SimpleTreeNode*)[targetNode nodeParent];
	    targetNodeIsValid = ![targetNode isDescendantOfNodeInArray: _draggedNodes];
		if( targetNodeIsValid ) targetNodeIsValid = [targetNode isParentOfNodesInArray: draggedNodes];
	}
    }
    
	if (targetNodeIsValid && !([info draggingSource]==outlineView))
		if( [[targetNode nodeData] itemType] == kPADTypeGroupFavorites ) return NSDragOperationCopy;
		else targetNodeIsValid = NO;
	
    // Set the item and child index in case we computed a retargeted one.
    [outlineView setDropItem:targetNode dropChildIndex:childIndex];
    
    return targetNodeIsValid ? NSDragOperationGeneric : NSDragOperationNone;
}

- (void)tableView:(NSTableView *)tableView sortDescriptorsDidChange:(NSArray *)oldDescriptors
{
    //[myTableDataArray sortUsingDescriptors:[tableView sortDescriptors]];
    [tableView reloadData];
}

- (void)_performDropOperation:(id <NSDraggingInfo>)info onNode:(TreeNode *)parentNode atIndex:(NSInteger)childIndex {
    // Helper method to insert dropped data into the model. 
    NSPasteboard *pboard = [info draggingPasteboard];
    NSMutableArray *itemsToSelect = nil;
    
    // Do the appropriate thing depending on wether the data is DragDropSimplePboardType or NSStringPboardType.
    if ([pboard availableTypeFromArray:[NSArray arrayWithObjects:DragDropSimplePboardType, nil]] != nil) {
        TreeController *dragDataSource = [[info draggingSource] dataSource];
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

    [outlineView reloadData];
    [outlineView selectItems:itemsToSelect byExtendingSelection: NO];
}

- (BOOL)outlineView:(NSOutlineView *)outlineView acceptDrop:(id <NSDraggingInfo>)info item:(id)item childIndex:(NSInteger)childIndex {
    // Determine the parent to insert into and the child index to insert at.
    SimpleTreeNode *node = (item == nil) ? treeData : item;
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
    
    [self _performDropOperation:info onNode:node atIndex:childIndex];
	
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

        
    return YES;
}


// On MacOS 10.5 and above, NSTableView and NSOutlineView have better contextual menu support. We now see a highlighted item for what was clicked on,
// and can access that item to do particular things (such as dynamically change the menu, as we do here!). Each of the contextual menus in the nib file
// have the delegate set to be the AppController instance. In menuNeedsUpdate, we dynamically update the menus based on the currently clicked upon row/column pair.
- (void)menuNeedsUpdate:(NSMenu *)menu {
	// Tell data source
	if( dataSource != nil ) [dataSource performSelector:@selector(menuNeedsUpdate:fromTree:) withObject:menu withObject:self];
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
    SimpleTreeNode *selectedNode = ([selectedNodes count] ? [selectedNodes objectAtIndex:0] : treeData);
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

- (void)removeAllChildren
{
	[[[[self treeControl] treeRoot] children] makeObjectsPerformSelector:@selector(removeFromParent)];
	[[[self treeControl] outlineView] reloadData];
}

- (id)toolbarControl { return toolbarControl; }
- (void)setToolbarControl:(id)tbar
{
	if( toolbarControl != nil ) [toolbarControl release];
	if( tbar != nil ) [tbar retain];
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
	
	if( colIndex == [theView columnWithIdentifier:COLUMNID_NAME] )
	{
		workNode = [theView itemAtRow:rowIndex];
		workCell = [theView preparedCellAtColumn:0 row:rowIndex];

		partHit = [workCell hitTestForEvent:[[NSApplication sharedApplication]currentEvent] inRect:rowFrame ofView:theView];
		
		if( partHit == NSCellHitNone ) {
			if([[workNode nodeData] isExpandable] == YES ) 
				if( [theView isItemExpanded:workNode] == YES ) {
					[theView collapseItem:workNode];
				} else {
					[theView expandItem:workNode];
				}
		} else if( partHit == NSCellHitIconArea ) {
			if( [self respondsToSelector:@selector(doubleClickImage:)] == YES )
				[self performSelector:@selector(doubleClickImage:) withObject:(id)workNode];
		}
	}
	
	return;
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
        
    } else if (menu == expandableColumnMenu) {
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

- (NSInteger)shouldEditTableColumn:(NSTableColumn *)tc item:(id)item
{
	return YES;
}

- (NSInteger)shouldSelectColumn:(NSTableColumn *)tc
{
	return NO;
}

@end	// TreeControllerDataSource

