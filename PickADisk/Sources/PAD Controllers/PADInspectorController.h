//
//  PADInspectorController.h
//  PickADisk
//
//  Created by Jack Small on 2/3/09.
//  Copyright 2009 Jack Small. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PADFlavorImageView.h"

@interface PADInspectorController : NSWindowController
{
	IBOutlet	NSImageView*			topIcon;
	IBOutlet	NSTextField*			topTitle;
	IBOutlet	NSTextField*			topStatus;
	IBOutlet	NSButton*				topButton;
	
	IBOutlet	NSTextField*			commentsText;
	
	IBOutlet	NSTokenField*			tagsTokens;
	
	IBOutlet	PADFlavorImageView*		generalTypeIcon;
	IBOutlet	NSPopUpButton*			generalType;
	IBOutlet	NSImageView*			generalDeviceIcon;
	IBOutlet	NSTextField*			generalDeviceName;
	IBOutlet	NSTextField*			generalDeviceSlot;
	IBOutlet	NSTextField*			generalPath;
	IBOutlet	NSTextField*			generalSize;
	IBOutlet	NSTextField*			generalAdded;
	IBOutlet	NSTextField*			generalStatus;
	IBOutlet	NSLevelIndicator*		generalRating;
	
	IBOutlet	NSTextField*			titleText;
	
	NSMutableArray*						selectedRecords;
}

+ (id)sharedInspector;

- (IBAction)clickGeneralType:(id)sender;
- (IBAction)clickGeneralWhere:(id)sender;
- (IBAction)clickGeneralRating:(id)sender;

- (IBAction)exitImage:(id)sender;
- (IBAction)exitComment:(id)sender;
- (IBAction)exitTags:(id)sender;
- (IBAction)exitTitle:(id)sender;

- (IBAction)clickTopButton:(id)sender;
- (void)toggleInspectorPanel:(id)sender;

- (void)extractSelectionDataAndClear:(BOOL)doClear;
- (void)installSelectionData;

- (BOOL)validateContextualMenuItem:(NSMenuItem *)menuItem withSelection:(NSArray*)newNodes;

- (void)dispatchInspectorPanelTo:(NSString*)doWhat withSelection:(NSArray*)theNodes;
- (void)adoptInspectorSelection:(NSArray*)newSelection;

- (void)nodeImageChanged:(SimpleTreeNode*)theNode toImage:(NSImage*)theImage;

// Search Watcher Protocol
- (void)searchStarted:(PADSearchRequest*)newSearch;
- (void)searchFinished:(PADSearchRequest*)newSearch;
- (void)searchDataChanged:(NSArray*)theItems;

@end	//	PADInspectorController

@interface PADInspectorControllerPanel : NSPanel
{
	//
}

-(NSUndoManager*)undoManager;

@end	//	PADInspectorControllerPanel



