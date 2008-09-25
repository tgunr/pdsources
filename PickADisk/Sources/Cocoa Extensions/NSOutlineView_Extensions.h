//
//  NSOutlineView_Extensions.h
//
//  Copyright (c) 2001-2005, Apple. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PADSearchRequest.h"

@interface NSOutlineView(MyExtensions)

- (NSArray *)allSelectedItems;
- (void)selectItems:(NSArray *)items byExtendingSelection:(BOOL)extend;

@end

@interface MyOutlineView : NSOutlineView
{
	PADSearchRequest*	currentSearch;
}

-(PADSearchRequest*)currentSearch;
-(void)setCurrentSearch:(PADSearchRequest*)newSearch;

- (void)draggedImage:(NSImage *)image endedAt:(NSPoint)screenPoint operation:(NSDragOperation)operation;
@end

