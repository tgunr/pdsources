//
//  JSServiceManager.m
//  PickADisk
//
//  Created by Jack Small on 9/27/08.
//  Copyright 2008 PolyMicro Systems. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "JSServiceManager.h"
#import "JSServicesSetup.h"
#import <PMSUtility/pms.h>

@implementation JSServiceAbstract

-(void)initSelf
{
    if ([self class] == [NSKeyedUnarchiver classForClassName:@"JSServiceAbstract"]) {
        PMLOG(1, @"WARNING: subclass should override this method!");
    }
}

-(id)init
{
	id	existingSelf = JSFindService( [self serviceName] );
	
	if( existingSelf && (existingSelf != self) )  {
        [self autorelease];
        return existingSelf;
    }
	if( self = [super init] )
	{
		[self initSelf];
	}
	return self;
}

+(id)sharedService
{
	NSString*		ourName = [self className];
	
	return JSFindService( ourName );
}

-(NSString*)serviceName
	{ return [self className]; }

-(NSArray*)dependentServices
	{ return nil; }

-(id)initializeService
{
	return self;
}

-(void)openService
{
    if ([self class] == [NSKeyedUnarchiver classForClassName:@"JSServiceAbstract"]) {
        PMLOG(1, @"WARNING: subclass should override this method!");
    }
}

-(void)closeService
{
    if ([self class] == [NSKeyedUnarchiver classForClassName:@"JSServiceAbstract"]) {
        PMLOG(1, @"WARNING: subclass should override this method!");
    }
}

@end	//	JSServiceAbstract

@implementation JSServiceManager
static id	JSServiceManager_appServiceManager = nil;

-(void)dealloc
{
	if( activeServices != nil )
	{
		[self closeServices];
		[activeServices release];
		activeServices = nil;
	}
	
	[super dealloc];
}

-(id)init {
    if (JSServiceManager_appServiceManager) {
        [self autorelease];
        return JSServiceManager_appServiceManager;
    }
	if( self = [super init] ) {
		JSServiceManager_appServiceManager = [self retain];
		activeServices = [[NSMutableArray alloc] initWithCapacity:0];
		PMLOG(3, @"JSService Manager Created");
	}
	return self;
}

+(id)sharedServices
{
	if (!JSServiceManager_appServiceManager) {
		[[JSServiceManager alloc] init];
	}
	return JSServiceManager_appServiceManager;
}

-(NSMutableArray*)activeServices
	{ return activeServices; }

-(id)findServiceWithName:(NSString*)serviceName
{
	id						outService = nil;
	JSServiceAbstract*		workService = nil;
	NSEnumerator*	servEnum = [activeServices objectEnumerator];

	while( workService = [servEnum nextObject] )
		if( [[workService serviceName] isEqual:serviceName] == YES )
		{
			outService = (id)workService;
			break;
		}
	
	return outService;
}

-(void)initializeServices
{
	NSArray*			workArray = JSServicesManagerInitialServices;
	NSEnumerator*		workEnum = [workArray objectEnumerator];
	NSString*			workName = nil;
	Class				serviceClass = nil;
	JSServiceAbstract*	serviceInstance = nil;
	
	while ( workName = [workEnum nextObject] )
	{		serviceClass = NSClassFromString( workName );
		if( serviceClass == nil )
			continue;
		
		if( serviceInstance = [self findServiceWithName:workName] )
			continue;
		else
            serviceInstance = [[serviceClass alloc] init];
		
		if( serviceInstance == nil )
			continue;
		
		if( serviceInstance = [serviceInstance initializeService] )
			[activeServices addObject:serviceInstance];
	}
	
}

-(void)openServices
	{ [activeServices makeObjectsPerformSelector:@selector(openService)]; }

-(void)closeServices
{
	[activeServices makeObjectsPerformSelector:@selector(closeService)]; 
	[activeServices removeAllObjects];
}

- (void)applicationWillFinishLaunching:(NSNotification *)notification
	{ [self initializeServices]; }

- (void)applicationDidFinishLaunching:(NSNotification *)notification
	{ [self openServices]; }

- (void)applicationWillTerminate:(NSNotification *)notification
	{ [self closeServices]; }

@end	//	JSServiceManager

id		JSFindService( NSString* serviceName )
	{ return [[JSServiceManager sharedServices] findServiceWithName:serviceName]; }

@implementation NSApplication(JSServiceManagerExtensions)

-(JSServiceManager*)serviceManager
	{ return [JSServiceManager sharedServices]; }

-(void)initializeServiceManager
	{ [[JSServiceManager sharedServices] initializeServices]; }

-(void)openServiceManager
	{ [[JSServiceManager sharedServices] openServices]; }

-(void)closeServiceManager
	{ [[JSServiceManager sharedServices] closeServices]; }

@end	//	NSApplication(JSServiceManagerExtensions)





