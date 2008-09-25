//
//  PADCarouselOperation.h
//  PickADisc
//
//  Created by Jack Small on 7/29/08.
//  Copyright 2008 Jack Small. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class PADOperationTask;

@interface PADCarouselOperation : NSOperation {

	PADOperationTask*	thisOperation;
	
	id					finishTarget;
	SEL					finishSelector;
	BOOL				canceled;
}

@property(retain)	PADOperationTask*	thisOperation;
@property(retain)	id					finishTarget;

-(SEL)finishSelector;
-(void)setFinishSelector:(SEL)newSel;

-(BOOL)cancelOperationForDevice:(DACALDevice*)oldBox;

-(id)initWithTarget:(id)theTarget endSelector:(SEL)theSelector;
+(id)startOperationTask:(id)opTask forTarget:(id)opTarget endSelector:(SEL)theSelector;

@end

@interface PADOperationTask : NSObject {

	DACALDevice*		theBoxRef;

}

-(DACALDevice*)theBoxRef;
-(void)setTheBoxRef:(DACALDevice*)newBox;

-(BOOL)newTaskForOperation:(PADCarouselOperation*)ownerOp;
-(void)queueTaskForOperation:(PADCarouselOperation*)ownerOp;
-(BOOL)runTaskForOperation:(PADCarouselOperation*)ownerOp;
-(id)endTaskForOperation:(PADCarouselOperation*)ownerOp;

-(BOOL)cancelOperationForDevice:(DACALDevice*)oldBox;
-(id)startNewOperationForTarget:(id)theTarget endSelector:(SEL)theSelector;

@end
