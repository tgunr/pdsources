//
//  PADURL.h
//  PickADisk
//
//  Copyright 2008 PolyMicro Systems. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface PADURL : NSURL {

	BOOL			localValid;
	FSRef			localRef;
	AliasHandle		localAlias;
}

-(id)resolve;
-(BOOL)localize;

-(id)initURLFromFileURL:(NSURL*)refURL;
+(id)padURLFromFileURL:(NSURL*)refURL;

@end
