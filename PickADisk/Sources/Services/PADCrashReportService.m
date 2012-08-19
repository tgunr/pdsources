//
//  PADCrashReportService.m
//  PickADisk
//
//  Copyright 2008 PolyMicro Systems. All rights reserved.
//

#import "PADCrashReportService.h"


@implementation PADCrashReportService

-(id)initializeService
{
	[[ILCrashReporter defaultReporter] launchReporterForCompany:@"PickADisk"
													 reportAddr:@"crashreport@pickadisk.com"];	

	return self;
}

@end		//	PADCrashReportService
