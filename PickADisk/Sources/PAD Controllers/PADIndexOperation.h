//
//  PADIndexOperation.h
//  PickADisc
//
//  Created by Jack Small on 7/15/08.
//  Copyright 2008 polyMicro Systems. All rights reserved.
//

@class SimpleTreeNode;
@class DACALDevice;

@interface PADIndexOperation : NSOperation {

	SimpleTreeNode		*subtreeChild;
	NSURL				*itemLocation;
	id					finishTarget;

}

@property(retain) SimpleTreeNode	*subtreeChild;
@property(retain) NSURL				*itemLocation;
@property(retain) id				finishTarget;

- (BOOL)cancelOperationForDevice:(DACALDevice*)oldBox;

- (id)initWithLocation:(NSURL*)url forChild:(SimpleTreeNode*)child;

// Prototype for completion selector is -(void)subTreeCompletedLoad:(SimpleTreeNode*)item
- (id)initWithLocation:(NSURL*)url forChild:(SimpleTreeNode*)child completionTarget:(id)target;
@end
