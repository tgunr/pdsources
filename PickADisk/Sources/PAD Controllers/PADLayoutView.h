//
//  PADLayoutView.h
//  PickADisk
//
//  Created by Jack Small on 8/2/08.
//  Copyright 2008 Jack Small. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <DACAL/pmsDACALUtility.h>

@interface PADLayoutView : NSView {

	DACALDeviceRef		reportDevice;
	BOOL				reportBlankSlots;
	
}

-(void)setReportDevice:(DACALDeviceRef)newDevice;
-(DACALDeviceRef)reportDevice;

-(void)setReportBlankSlots:(BOOL)drawSlots;
-(BOOL)reportBlankSlots;

+ (id)printReportForDevice:(DACALDeviceRef)box forSender:(id)sender;

@end
