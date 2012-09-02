// DACALSlotElement.h
// Created by davec on 8/19/12.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import <Cocoa/Cocoa.h>
@class DACALSlot;
@class SimpleTreeNode;
@class DACALDevice;
@class DACALSlotElementBookmark;
@class NSImage;

@interface DACALSlotElement : NSObject {

	DACALSlot*			elementSlot;
	SimpleTreeNode*		elementNode;
	FSRef				elementFSRef;
	NSURL*				elementURL;

	NSMutableArray*		elementBookmarks;

	NSString*			comments;
	NSArray*			tags;
	NSInteger			stars;
}

-(DACALSlot*)elementSlot;
-(DACALDevice*)elementDevice;
-(FSRef*)elementFSRef;
-(NSURL*)elementURL;
-(BOOL)isElementFSRef:(const FSRef*)otherFSRef;
-(BOOL)isElementURL:(NSURL*)otherURL;

-(SimpleTreeNode*)elementNode;
-(void)setElementNode:(SimpleTreeNode*)newNode;

//- (NSUndoManager*)undoManager;

-(id)initElementForSlot:(DACALSlot*)newSlot atLocation:(NSURL*)newLoc;
+(id)slotElementForSlot:(DACALSlot*)newSlot atLocation:(NSURL*)newLoc;
+(id)slotElementForNode:(SimpleTreeNode*)newNode;

-(void)updateElementChanges:(BOOL)doAction;
-(void)reloadElement;

-(NSString*)title;
-(void)setTitle:(NSString*)newTitle;

-(NSString*)flavor;
-(void)setFlavor:(NSString*)newFlavor;

-(BOOL)isCheckedOut;
-(NSDate*)checkedOutDate;
-(NSDate*)checkedInDate;

-(NSString*)comments;
-(void)setComments:(NSString*)newComment;

-(NSArray*)tags;
-(void)setTags:(NSArray*)newTags;

-(NSInteger)stars;
-(void)setStars:(NSInteger)starLevel;

-(BOOL)openMountedElement;

-(NSMutableArray*)bookmarks;
-(BOOL)removeBookmarkForLocation:(NSString*)markLocation;
-(DACALSlotElementBookmark*)bookmarkForLocation:(NSString*)markLocation;
-(DACALSlotElementBookmark*)createBookmarkAtLocation:(NSString*)markLocation attachNow:(BOOL)doAttach;

-(BOOL)changeElementIconRep:(NSImage*)newIcon;

@end		//	DACALSlotElement
