//
//  PADIndexNodeData.h
//  PickADisk
//
//  Created by Jack Small on 8/27/08.
//  Copyright 2008 Jack Small. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "SimpleTreeNode.h"
#import "PADSearchRequest.h"

PADSearchRequest* PADCreateSearchForType( OSType aType );

@class PADSearchRequest;

@interface IndexNodeData : SimpleNodeData {
	PADSearchRequest*		itemSearch;
}

-(PADSearchRequest*)itemSearch;
-(void)setItemSearch:       (PADSearchRequest*)newSearch;

@end

@interface SimpleTreeNode(PADIndexExtensions)

- (id)initIndexFromDictionary:(NSDictionary*)dict;
+ (id)treeIndexFromDictionary:(NSDictionary *)dict;

@end