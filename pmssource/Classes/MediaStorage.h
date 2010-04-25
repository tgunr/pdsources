//
//  MediaStorage.h
//  DACALTester
//
//  Created by Dave Carlton on 02/16/10.
//  Copyright 2010 PolyMicro Systems. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <IOKit/IOKitLib.h>

@class NSMutableArray;

@interface MediaStorage : NSObject {
	NSMutableArray * theDeviceList; // array of Media devices

	IONotificationPortRef deviceNotifyPort;
	io_iterator_t         deviceAppearedIterator;
	io_iterator_t         deviceDisappearedIterator;
}

@property (assign) NSMutableArray      * theDeviceList;
@property (assign) IONotificationPortRef deviceNotifyPort;
@property (assign) io_iterator_t         deviceAppearedIterator;
@property (assign) io_iterator_t         deviceDisappearedIterator;

-(void) registerDeviceCallbackHandler;
-(kern_return_t) FindEjectableCDMedia: (io_iterator_t *) iterator;
-(kern_return_t) FindMedia: (io_iterator_t *) iterator: (CFMutableDictionaryRef) dict;
-(kern_return_t) FindMedia: (io_iterator_t *) iterator: (char *) class : (char *) type;
-(kern_return_t) GetBSDPath: (io_iterator_t) mediaIterator: (char *) bsdPath: (CFIndex) maxPathSize;
-(int) OpenDrive: (const char *) bsdPath;
-(Boolean) ReadSector: (int) fileDescriptor;
-(void) CloseDrive: (int) fileDescriptor;

@end

