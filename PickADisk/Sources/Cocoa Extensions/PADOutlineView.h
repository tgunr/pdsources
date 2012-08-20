//
//  PADOutlineView.h
//
//  Copyright (c) 2001-2005, Apple. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class PADSearchRequest;

@interface PADOutlineView : NSOutlineView
{
	PADSearchRequest*	currentSearch;
}

-(PADSearchRequest*)currentSearch;
-(void)setCurrentSearch:(PADSearchRequest*)newSearch;

- (id)selectedItem;
- (NSArray *)allSelectedItems;
- (NSArray *)allSelectedNodes;
- (void)selectItems:(NSArray *)items byExtendingSelection:(BOOL)extend;
- (void)selectNodes:(NSArray *)items byExtendingSelection:(BOOL)extend;
- (void)selectItems:(NSArray*)items;
- (void)extendSelectItems:(NSArray*)items;
- (void)autoExpandItemAndChildren:(id)item;
-(void)reloadData;
- (id)initWithCoder:(NSCoder *)decoder;
-(void)searchDataChanged:(NSArray*)theItems;
-(void)searchStarted:(PADSearchRequest*)newSearch;
-(void)searchFinished:(PADSearchRequest*)newSearch;
- (BOOL)validateMenuItem:(NSMenuItem *)menuItem;
- (void)draggedImage:(NSImage *)image endedAt:(NSPoint)screenPoint operation:(NSDragOperation)operation;
@end

