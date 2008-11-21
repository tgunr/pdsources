//
//  PADCrashReportService.m
//  PickADisk
//
//  Created by Jack Small on 11/8/08.
//  Copyright 2008 Jack Small. All rights reserved.
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
