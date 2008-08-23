//
//  PADOperationOpenDevice.h
//  PickADisk
//
//  Created by Jack Small on 8/16/08.
//  Copyright 2008 Jack Small. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PADCarouselOperation.h"
#import "SimpleTreeNode.h"

@interface PADOperationOpenDevice : PADOperationTask {

	SimpleTreeNode*		theDeviceNode;
}

-(SimpleTreeNode*)theDeviceNode;
-(void)setTheDeviceNode:(SimpleTreeNode*)newNode;

+(BOOL)addDeviceToSourceTree:(DACALDeviceRef)newBox forTarget:(id)theTarget endSelector:(SEL)theSelector;

@end
