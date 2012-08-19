//
//  PADLayoutView.h
//  PickADisk
//
//  Copyright 2008 PolyMicro Systems. All rights reserved.
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
