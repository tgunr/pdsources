//
//  PADOperationOpenDevice.h
//  PickADisk
//
//  Copyright 2008 PolyMicro Systems. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PADCarouselOperation.h"
#import "SimpleTreeNode.h"

@interface PADOperationOpenDevice : PADOperationTask {

	SimpleTreeNode*		theDeviceNode;
}

-(SimpleTreeNode*)theDeviceNode;
-(void)setTheDeviceNode:(SimpleTreeNode*)newNode;

+(BOOL)addDeviceToSourceTree:(DACALDevice*)newBox;

@end
