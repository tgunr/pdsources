/*
 *  JSServicesSetup.h
 *  PickADisk
 *
 *  Copyright 2008 PolyMicro Systems. All rights reserved.
 *
 */

//	You should define this nil terminated array yourself, probably in the predfeined headers
//		with the NSString names of the services CLASSES you want to initally make into instances
//		i.e.:
//	#define		JSServicesManagerInitialServices		[NSArray arrayWithObjects:	@"ServiceA", @"ServiceB", nil]

#ifndef	JSSMIS_SETUP
#define JSSMIS_SETUP

#define		JSServicesManagerInitialServices		 [NSArray arrayWithObjects: @"DACALDeviceService", \
                                                                                @"PADBOXController", \
																				@"DACVolumeService", \
																				@"PADFolderService", \
                                                                                @"PADLicenseService", \
                                                                                @"PADSearchService", \
																				nil]

#endif	// JSSMIS_SETUP