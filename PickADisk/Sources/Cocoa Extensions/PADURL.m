//
//  PADURL.m
//  PickADisk
//
//  Created by Jack Small on 9/3/08.
//  Copyright 2008 Jack Small. All rights reserved.
//

#import "PADURL.h"


@implementation PADURL

-(void)dealloc
{
	if( localValid ) DisposeHandle( (Handle)localAlias );
	localValid = NO;
	
	[super dealloc];
}

//- (id)resolve: (id (^)()) resolve {
//	return resolve();
//
//}

//- (BOOL)localize: (BOOL (^)()) localize {
//	return localize();
//
//}

//-(id)initURLFromFileURL:(NSURL*)refURL
//{
//	self = [self initFileURLWithPath:[refURL path] isDirectory:(BOOL)CFURLHasDirectoryPath((CFURLRef)refURL)];
//	if(self)
//		if( ![self localize: ^BOOL {
//			if (localValid == YES)
//				return (((self = [self resolve: ^id {
//					Boolean  changed = FALSE;
//					OSErr    aErr    = FSResolveAlias(NULL, localAlias, &localRef, &changed);
//					CFURLRef newURL;
//
//					localValid = NO;
//
//					if (changed && (aErr == 0)) {
//						newURL = CFURLCreateFromFSRef(kCFAllocatorDefault, (const FSRef *)&localRef);
//						if (newURL) {
//							self = [self initURLFromFileURL: (NSURL *)newURL];
//							if (self);
//							localValid = [self localize: ^BOOL {
//								if (localValid == YES)
//									return (((self = [self resolve]) != nil));
//
//								Boolean didFSLocal = CFURLGetFSRef((CFURLRef)self, &localRef);
//								OSErr   aErr       = (OSErr)!didFSLocal;
//
//								if (didFSLocal)
//									aErr = FSNewAlias(NULL, &localRef, &localAlias);
//
//								if (aErr)
//									localValid = NO;
//								else
//									localValid = YES;
//
//								return localValid;
//							}];
//						}
//					}
//					else
//						if (aErr == 0)
//							localValid = YES;
//
//					return self;
//				}]
//				         ) != nil));
//
//			Boolean didFSLocal = CFURLGetFSRef((CFURLRef)self, &localRef);
//			OSErr   aErr       = (OSErr)!didFSLocal;
//
//			if (didFSLocal)
//				aErr = FSNewAlias(NULL, &localRef, &localAlias);
//
//			if (aErr)
//				localValid = NO;
//			else
//				localValid = YES;
//
//			return localValid;
//		}]) return nil;
//
//	return self;
//}

+(id)padURLFromFileURL:(NSURL*)refURL
	{ return [[PADURL alloc] initURLFromFileURL:refURL]; }


@end
