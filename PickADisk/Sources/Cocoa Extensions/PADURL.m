//
//  PADURL.m
//  PickADisk
//
//  Copyright 2008 PolyMicro Systems. All rights reserved.
//

#import "PADURL.h"


@implementation PADURL

-(void)dealloc
{
	if( localValid ) DisposeHandle( (Handle)localAlias );
	localValid = NO;
	
	[super dealloc];
}

-(id)resolve
{
	Boolean		changed = FALSE;
	OSErr		aErr = FSResolveAlias( NULL, localAlias, &localRef, &changed );
	CFURLRef	newURL = NULL;
//	PADURL*		newSelf = NULL;
	
	localValid = NO;
	
	if( changed && (aErr == 0) )
	{
		newURL = CFURLCreateFromFSRef( kCFAllocatorDefault, (const FSRef*)&localRef );
		if( newURL ) 
		{
			if( self = [self initURLFromFileURL:(NSURL*)newURL] );
				localValid = [self localize];
		}
	} else if( aErr == 0 )
		localValid = YES;
	
	return self;		
}

-(BOOL)localize
{
	if( localValid == YES ) return( ((self = [self resolve]) != nil) );
	
	Boolean		didFSLocal = CFURLGetFSRef( (CFURLRef)self, &localRef );
	OSErr		aErr = (OSErr)!didFSLocal;
	
	if( didFSLocal )
		aErr = FSNewAlias( NULL, &localRef, &localAlias );
	
	if( aErr ) localValid = NO;
	else localValid = YES;
	
	return localValid;
}

-(id)initURLFromFileURL:(NSURL*)refURL
{
	if( self = [self initFileURLWithPath:[refURL path] isDirectory:(BOOL)CFURLHasDirectoryPath((CFURLRef)refURL)] )
		if( ![self localize] ) return nil;
		
	return self;
}

+(id)padURLFromFileURL:(NSURL*)refURL
	{ return [[PADURL alloc] initURLFromFileURL:refURL]; }


@end
