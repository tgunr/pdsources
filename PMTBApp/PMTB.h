//
//  PMTB.h
//  PMTB
//
//  Created by Dave Carlton on 04/15/08.
//  Copyright 2008 PolyMicro Systems. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#if 1
#define LOG_OP(fmt, ...) NSLog(fmt, ## __VA_ARGS__)
#else
#define LOG_OP(fmt, ...) do {} while(0)
#endif

@class GMUserFileSystem;

@interface PMTB : NSObject {
	NSString* rootPath_;   // The local file-system path to mount.
	NSDictionary* data_;
}

- (id)initWithData:(NSDictionary *)data;
- (id)initWithRootPath:(NSString *)rootPath;
- (void)dealloc;

@end

@interface PMTB (PMTBUtil)	

- (NSXMLNode *)nodeAtPath:(NSString *)path;

@end
