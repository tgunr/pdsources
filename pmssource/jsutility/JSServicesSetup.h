/*
 *  JSServicesSetup.h
 *  PickADisk
 *
 *  Created by Jack Small on 9/27/08.
 *  Copyright 2008 Jack Small. All rights reserved.
 *
 */

//	You should define this nil terminated array yourself, probably in the predfeined headers
//		with the NSString names of the services CLASSES you want to initally make into instances
//		i.e.:
//	#define		JSServicesManagerInitialServices		[NSArray arrayWithObjects:	@"ServiceA", @"ServiceB", nil]

#ifndef	JSSMIS_SETUP
#define JSSMIS_SETUP

#define		JSServicesManagerInitialServices		 [NSArray arrayWithObjects: @"PADBOXController", \
																				@"PADLicenseService", \
																				@"PADCrashReportService", \
																				@"DACVolumeService", \
																				@"DACALDeviceService", \
																				@"PADSearchService", \
																				nil]

#endif	JSSMIS_SETUP