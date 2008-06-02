// PMTBFileSystem.h

#import <Cocoa/Cocoa.h>

@interface PMTBFileSystem : NSObject
	NSString* rootPath_;   // The local file-system path to mount.

	- (id)initWithRootPath:(NSString *)rootPath;
	- (void)dealloc;
@end
