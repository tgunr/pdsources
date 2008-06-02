#import <sys/xattr.h>
#import <sys/stat.h>
#import "PMTBFileSystem.h"
#import <MacFUSE/GMUserFileSystem.h>
#import "NSError+POSIX.h"


static NSString *helloStr = @"Hello World!\n";
static NSString *helloPath = @"/hello.txt";

@implementation PMTBFileSystem

#if 1
#define LOG_OP(fmt, ...) NSLog(fmt, ## __VA_ARGS__)
#else
#define LOG_OP(fmt, ...) do {} while(0)
#endif

- (id)initWithRootPath:(NSString *)rootPath {
	if ((self = [super init])) {
		rootPath_ = [rootPath retain];
	}
	return self;
}

- (void) dealloc {
	[rootPath_ release];
	[super dealloc];
}

//- (NSArray *)contentsOfDirectoryAtPath:(NSString *)path error:(NSError **)error {
//	return [NSArray arrayWithObject:[helloPath lastPathComponent]];
//}
//
- (NSData *)contentsAtPath:(NSString *)path {
	if ([path isEqualToString:helloPath])
		return [helloStr dataUsingEncoding:NSUTF8StringEncoding];
	return nil;
}

#pragma optional icon method

- (NSData *)iconDataAtPath:(NSString *)path {
	if ([path isEqualToString:helloPath]) {
		NSString *file = [[NSBundle mainBundle] pathForResource:@"hellodoc" ofType:@"icns"];
		return [NSData dataWithContentsOfFile:file];
	}
	return nil;
}

#pragma mark Directory Contents

- (NSArray *)contentsOfDirectoryAtPath:(NSString *)path error:(NSError **)error {
	LOG_OP(@"[0x%x] directory contents: %@", [NSThread currentThread], path);
	
	NSString* p = [rootPath_ stringByAppendingString:path];
	return [[NSFileManager defaultManager] contentsOfDirectoryAtPath:p error:error];
}

#pragma mark Getting and Setting Attributes

- (NSDictionary *)attributesOfItemAtPath:(NSString *)path 
                                   error:(NSError **)error {
	LOG_OP(@"[0x%x] attributesOfItemAtAPath: %@", [NSThread currentThread], path);
	
	NSString* p = [rootPath_ stringByAppendingString:path];
	return [[NSFileManager defaultManager] attributesOfItemAtPath:p error:error];
}

- (NSDictionary *)attributesOfFileSystemForPath:(NSString *)path
                                          error:(NSError **)error {
	LOG_OP(@"[0x%x] attributesOfFileSystemForPath: %@", 
		   [NSThread currentThread], path);
	
	NSString* p = [rootPath_ stringByAppendingString:path];
	return [[NSFileManager defaultManager] attributesOfFileSystemForPath:p error:error];
}

- (BOOL)setAttributes:(NSDictionary *)attributes 
         ofItemAtPath:(NSString *)path
                error:(NSError **)error {
	LOG_OP(@"[0x%x] setAttributes:%@ ofItemAtPath: %@", 
		   [NSThread currentThread], attributes, path);
	
	NSString* p = [rootPath_ stringByAppendingString:path];
	return [[NSFileManager defaultManager] setAttributes:attributes
											ofItemAtPath:p
												   error:error];
}

#pragma mark Extended Attributes

- (NSArray *)extendedAttributesOfItemAtPath:(NSString *)path error:(NSError **)error {
	LOG_OP(@"[0x%x] extended Attributes: %@", [NSThread currentThread], path);
	
	NSString* p = [rootPath_ stringByAppendingString:path];
	
	ssize_t size = listxattr([p UTF8String], nil, 0, 0);
	if ( size < 0 ) {
		*error = [NSError errorWithPOSIXCode:errno];
		return nil;
	}
	NSMutableData* data = [NSMutableData dataWithLength:size];
	size = listxattr([p UTF8String], [data mutableBytes], [data length], 0);
	if ( size < 0 ) {
		*error = [NSError errorWithPOSIXCode:errno];
		return nil;
	}
	NSMutableArray* contents = [NSMutableArray array];
	char* ptr = (char *)[data bytes];
	while ( ptr < ((char *)[data bytes] + size) ) {
		NSString* s = [NSString stringWithUTF8String:ptr];
		[contents addObject:s];
		ptr += ([s length] + 1);
	}
	return contents;
}

- (NSData *)valueOfExtendedAttribute:(NSString *)name 
                        ofItemAtPath:(NSString *)path
                               error:(NSError **)error {
	LOG_OP(@"[0x%x] value of extended attribute: %@ forPath:%@", 
		   [NSThread currentThread], name, path);
	
	NSString* p = [rootPath_ stringByAppendingString:path];
	
	ssize_t size = getxattr([p UTF8String], [name UTF8String], nil, 0,
							0, 0);
	if ( size < 0 ) {
		*error = [NSError errorWithPOSIXCode:errno];
		return nil;
	}
	NSMutableData* data = [NSMutableData dataWithLength:size];
	size = getxattr([p UTF8String], [name UTF8String], 
					[data mutableBytes], [data length],
					0, 0);
	if ( size < 0 ) {
		*error = [NSError errorWithPOSIXCode:errno];
		return nil;
	}  
	return data;
}

- (BOOL)setExtendedAttribute:(NSString *)name 
                ofItemAtPath:(NSString *)path 
                       value:(NSData *)value
                       flags:(int)flags
                       error:(NSError **)error {
	LOG_OP(@"[0x%x] set extended attribute: %@ forPath:%@", 
		   [NSThread currentThread], name, path);
	
	NSString* p = [rootPath_ stringByAppendingString:path];
	int ret = setxattr([p UTF8String], [name UTF8String], 
					   [value bytes], [value length], 
					   0, 0);
	if ( ret < 0 ) {
		*error = [NSError errorWithPOSIXCode:errno];
		return NO;
	}
	return YES;
}

- (BOOL)removeExtendedAttribute:(NSString *)name
                   ofItemAtPath:(NSString *)path
                          error:(NSError **)error {
	LOG_OP(@"[0x%x] set extended attribute: %@ forPath:%@", 
		   [NSThread currentThread], name, path);
	
	NSString* p = [rootPath_ stringByAppendingString:path];
	int ret = removexattr([p UTF8String], [name UTF8String], 0);
	if ( ret < 0 ) {
		*error = [NSError errorWithPOSIXCode:errno];
		return NO;
	}
	return YES;
}


@end
