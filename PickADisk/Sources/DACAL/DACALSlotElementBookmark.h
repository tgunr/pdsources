//
// Created by davec on 8/19/12.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import <Cocoa/Cocoa.h>
@class DACALSlotElement;
@class SimpleTreeNode;


@interface DACALSlotElementBookmark : NSObject
{
	DACALSlotElement*	markElement;
	NSString*			markLocation;
	SimpleTreeNode*		markNode;
}

-(DACALSlotElement*)markElement;
-(NSString*)markLocation;
-(SimpleTreeNode*)markNode;

-(BOOL)isBookmarkLocation:(NSString*)theLocation;
-(BOOL)removeBookmark;
-(void)removeMarkNode;

-(id)initBookmarkForElement:(DACALSlotElement*)theElement atLocation:(NSString*)theLocation attachNow:(BOOL)doAttach;
+(id)bookmarkForElement:(DACALSlotElement*)theElement atLocation:(NSString*)theLocation attachNow:(BOOL)doAttach;

@end	//	DACALSlotElementBookmark
