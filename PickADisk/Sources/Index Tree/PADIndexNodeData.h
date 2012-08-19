//
//  PADIndexNodeData.h
//  PickADisk
//
//  Copyright 2008 PolyMicro Systems. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "TreeNode.h"
#import "SimpleTreeNode.h"

@class PADSearchRequest;

@interface IndexNodeData : SimpleNodeData {

	PADSearchRequest*		itemSearch;
}

-(PADSearchRequest*)itemSearch;
-(void)setItemSearch:(PADSearchRequest*)newSearch;

@end

@interface SimpleTreeNode(PADIndexExtensions)

- (id)initIndexFromDictionary:(NSDictionary*)dict;
+ (id)treeIndexFromDictionary:(NSDictionary *)dict;

@end