/*
    TreeNode.m
    Copyright (c) 2001-2006, Apple Computer, Inc., all rights reserved.
    Author: Chuck Pisula

    Milestones:
    * 03-01-2001: Initial creation by Chuck Pisula
    * 02-17-2006: Cleaned up the code. Corbin Dunn.

    Generic Tree node structure (TreeNode).
    
    TreeNode is a node in a doubly linked tree data structure.  TreeNode's have weak references to their parent (to avoid retain 
    cycles since parents retain their children).  Each node has 0 or more children and a reference to a piece of node data. The TreeNode provides method to manipulate and extract structural information about a tree.  For instance, TreeNode implements: insertChild:atIndex:, removeChild:, isDescendantOfNode:, and other useful operations on tree nodes.
    TreeNode provides the structure and common functionality of trees and is expected to be subclassed.
*/

/*
 IMPORTANT:  This Apple software is supplied to you by Apple Computer, Inc. ("Apple") in
 consideration of your agreement to the following terms, and your use, installation, 
 modification or redistribution of this Apple software constitutes acceptance of these 
 terms.  If you do not agree with these terms, please do not use, install, modify or 
 redistribute this Apple software.
 
 In consideration of your agreement to abide by the following terms, and subject to these 
 terms, Apple grants you a personal, non-exclusive license, under Apple’s copyrights in 
 this original Apple software (the "Apple Software"), to use, reproduce, modify and 
 redistribute the Apple Software, with or without modifications, in source and/or binary 
 forms; provided that if you redistribute the Apple Software in its entirety and without 
 modifications, you must retain this notice and the following text and disclaimers in all 
 such redistributions of the Apple Software.  Neither the name, trademarks, service marks 
 or logos of Apple Computer, Inc. may be used to endorse or promote products derived from 
 the Apple Software without specific prior written permission from Apple. Except as expressly
 stated in this notice, no other rights or licenses, express or implied, are granted by Apple
 herein, including but not limited to any patent rights that may be infringed by your 
 derivative works or by other works in which the Apple Software may be incorporated.
 
 The Apple Software is provided by Apple on an "AS IS" basis.  APPLE MAKES NO WARRANTIES, 
 EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, 
 MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS 
 USE AND OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
 
 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL OR CONSEQUENTIAL 
 DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS 
 OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, 
 REPRODUCTION, MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED AND 
 WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE), STRICT LIABILITY OR 
 OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

#import "TreeNode.h"

@implementation TreeNode

+ (id)treeNodeWithData:(id)data {
    return [[[TreeNode alloc] initWithData:data  parent:nil children:[NSArray array]] autorelease]; 
}

- (id)initWithData:(id)data parent:(TreeNode *)parent children:(NSArray *)children {
    if (self = [super init]) {
        nodeData = [data retain];
        nodeChildren = [[NSMutableArray arrayWithArray:children] retain];
        nodeParent = parent;
    }
    
    return self;
}

- (void)dealloc {
    [nodeData release];
    [nodeChildren release];
    [super dealloc];
}

// ================================================================
// Methods used to manage a node and its children.
// ================================================================

- (void)setNodeData:(id)data { 
    if (nodeData != data) {
        [nodeData release]; 
        nodeData = [data retain]; 
    }
}

- (id)nodeData { 
    return nodeData; 
}

- (void)setNodeParent:(TreeNode *)parent {
    nodeParent = parent; 
}

- (TreeNode *)nodeParent { 
    return nodeParent; 
}

- (void)insertChild:(TreeNode *)child atIndex:(NSInteger)index {
    [nodeChildren insertObject:child atIndex:index];
    [child setNodeParent:self];
}

- (void)insertChildren:(NSArray *)children atIndex:(NSInteger)index {
    [nodeChildren insertObjectsFromArray:children atIndex:index];
    [children makeObjectsPerformSelector:@selector(setNodeParent:) withObject:self];
}

- (void)_removeChildrenIdenticalTo:(NSArray *)childlist {
    TreeNode *child;
    NSEnumerator *childEnumerator = [childlist objectEnumerator];
    [childlist makeObjectsPerformSelector:@selector(setNodeParent:) withObject:nil];
    while ((child = [childEnumerator nextObject])) {
        [nodeChildren removeObjectIdenticalTo:child];
    }
}

- (void)removeChildrenIdenticalTo:(NSArray *)childlist
	{ [self _removeChildrenIdenticalTo:childlist]; }

- (void)removeChild:(TreeNode *)child {
    NSInteger index = [self indexOfChild:child];
    if (index != NSNotFound) {
        [self _removeChildrenIdenticalTo:[NSArray arrayWithObject:[self childAtIndex:index]]];
    }
}

- (void)removeFromParent {
    [[self nodeParent] removeChild:self];
}

- (NSInteger)indexOfChild:(TreeNode *)child {
    return [nodeChildren indexOfObject:child];
}

- (NSInteger)indexOfChildIdenticalTo:(TreeNode *)child {
    return [nodeChildren indexOfObjectIdenticalTo:child];
}

- (NSInteger)numberOfChildren {
    return [nodeChildren count];
}

- (NSArray *)children {
    return [NSArray arrayWithArray: nodeChildren];
}

- (TreeNode *)firstChild {
    return [nodeChildren objectAtIndex:0];
}

- (TreeNode *)lastChild {
    return [nodeChildren lastObject];
}

- (TreeNode*)childAtIndex:(NSInteger)index {
    return [nodeChildren objectAtIndex:index];
}

- (BOOL)isDescendantOfNode:(TreeNode *)node {
    // returns YES if 'node' is an ancestor.
    // Walk up the tree, to see if any of our ancestors is 'node'.
    TreeNode *parent = self;
    while (parent) {
        if (parent == node) return YES;
        parent = [parent nodeParent];
    }
    return NO;
}

- (BOOL)isDescendantOfNodeInArray:(NSArray *)nodes {
    // returns YES if any 'node' in the array 'nodes' is an ancestor of ours.
    // For each node in nodes, if node is an ancestor return YES.  If none is an
    // ancestor, return NO.
    NSEnumerator *nodeEnum = [nodes objectEnumerator];
    TreeNode *node = nil;
    while ((node = [nodeEnum nextObject])) {
        if ([self isDescendantOfNode:node]) return YES;
    }
    return NO;
}

- (BOOL)isParentOfNode:(TreeNode *)node {
    // returns YES if 'node' is the parent.
	if( [node nodeParent] == self ) return YES;
	return NO;
}

- (BOOL)isParentOfNodesInArray:(NSArray *)nodes {
    // returns YES if every 'node' in the array 'nodes' is an parent of ours.
    // For each node in nodes, if node is the not parent return NO.  If every none
    // in the array is a child, return YES.
    NSEnumerator *nodeEnum = [nodes objectEnumerator];
    TreeNode *node = nil;
    while ((node = [nodeEnum nextObject])) {
        if (![self isParentOfNode:node]) return NO;
    }
    return YES;
}

- (void)reloadData:(id)newData reloadChildren:(BOOL)recurse
{
	if( [self nodeData] == nil )
		[self setNodeData:[newData reload]];
	else
		[self setNodeData:[[self nodeData] reloadData:newData]];
	
	if( recurse == YES )
		[nodeChildren makeObjectsPerformSelector:@selector(reloadDataAndChildren)];
}

- (void)reloadDataAndChildren
	{ [self reloadData:nil reloadChildren:YES]; }


- (void)orderChildrenByName:(NSArray*)childNames removeMissing:(BOOL)doRemove
{
	NSMutableArray*		moveNames = [NSMutableArray arrayWithCapacity:0];
	NSInteger			childIndex, childCount = [childNames count];
	NSInteger			totalChildren = [self numberOfChildren] - 1;
	SimpleTreeNode*		workChild = nil;
	
	[moveNames addObjectsFromArray:childNames];
	
	for ( childIndex=0; childIndex < childCount; childIndex++ ) {
		if( childIndex > totalChildren ) break;
		workChild = [(SimpleTreeNode*)self childWithName:[childNames objectAtIndex:childIndex]];
		if( workChild != nil )
		{
			if( [workChild isEqual:[nodeChildren objectAtIndex:childIndex]] == YES )
				continue;
			
			[nodeChildren exchangeObjectAtIndex:childIndex withObjectAtIndex:[nodeChildren indexOfObject:workChild]];
		}
		else
			[moveNames removeObject:[childNames objectAtIndex:childIndex]];
	}
	
	childCount = [moveNames count];
	
	if( doRemove && ([self numberOfChildren] >= childCount ) )
		for ( childIndex = totalChildren; childIndex >= childCount; childIndex-- )
			[[nodeChildren objectAtIndex:childIndex] removeFromParent];
}

- (void)recursiveSortChildren {
    [nodeChildren sortUsingSelector:@selector(compare:)];
    [nodeChildren makeObjectsPerformSelector:@selector(recursiveSortChildren)];
}

- (void)sortChildrenUsingDescriptors:(NSArray*)newDescriptors
	{ [nodeChildren sortUsingDescriptors:newDescriptors]; }

- (void)sortExpandedChildrenUsingDescriptors:(NSArray*)newDescriptors
{
	[nodeChildren sortUsingDescriptors:newDescriptors];
	if( [[self nodeData] isExpanded] ) {
		[nodeChildren makeObjectsPerformSelector:@selector(sortExpandedChildrenUsingDescriptors:) withObject:newDescriptors];
	}
}

- (void)sortExpandedChildrenForView:(NSOutlineView*)theView
	{ [self sortExpandedChildrenUsingDescriptors:[theView sortDescriptors]]; }

- (void)recursiveReExpandInView:(NSOutlineView*)theView
{
    [nodeChildren makeObjectsPerformSelector:@selector(recursiveReExpandInView:) withObject:theView];
	if( [[self nodeData] isExpanded] ) [theView expandItem:self];
}


- (void)recursiveSortChildrenUsingDescriptors:(NSArray*)newDescriptors
{
    [nodeChildren sortUsingDescriptors:newDescriptors];
    [nodeChildren makeObjectsPerformSelector:@selector(recursiveSortChildrenUsingDescriptors:) withObject:newDescriptors];
}

- (NSString *)description {
    // Return something that will be useful for debugging.
    return [NSString stringWithFormat:@"%@ - nodeData: %@", [super description], nodeData];
}

// Returns the minimum nodes from 'allNodes' required to cover the nodes in 'allNodes'.
// This methods returns an array containing nodes from 'allNodes' such that no node in
// the returned array has an ancestor in the returned array.

// There are better ways to compute this, but this implementation should be efficient for our app.
+ (NSArray *)minimumNodeCoverFromNodesInArray:(NSArray *)allNodes {
    NSMutableArray *minimumCover = [NSMutableArray array];
    NSMutableArray *nodeQueue = [NSMutableArray arrayWithArray:allNodes];
    TreeNode *node = nil;
    while ([nodeQueue count]) {
        node = [nodeQueue objectAtIndex:0];
        [nodeQueue removeObjectAtIndex:0];
        while ( [node nodeParent] && [nodeQueue containsObjectIdenticalTo:[node nodeParent]] ) {
            [nodeQueue removeObjectIdenticalTo: node];
            node = [node nodeParent];
        }
        if (![node isDescendantOfNodeInArray: minimumCover]) [minimumCover addObject: node];
        [nodeQueue removeObjectIdenticalTo: node];
    }
    return minimumCover;
}

- (NSComparisonResult)compare:(TreeNode *)node {
    // Compare nodes to each other by comparing the data part.
    return [nodeData compare:[node nodeData]];
}

@end
