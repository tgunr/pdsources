//
//  PADURL.h
//  PickADisk
//
//  Created by Jack Small on 9/3/08.
//  Copyright 2008 Jack Small. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface PADURL : NSURL {

	BOOL			localValid;
	FSRef			localRef;
	AliasHandle		localAlias;
}

//- (id)resolve: (id (^)()) resolve;
//
//- (BOOL)localize: (BOOL (^)()) localize;
//
//-(id)initURLFromFileURL:(NSURL*)refURL;
+(id)padURLFromFileURL:(NSURL*)refURL;

@end
