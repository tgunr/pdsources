//
//  JSServiceManager.h
//  PickADisk
//
//  Created by Jack Small on 9/27/08.
//  Copyright 2008 Jack Small. All rights reserved.
//

#import <Cocoa/Cocoa.h>

//extern const NSString*	JSServicesManagerInitialServices[];
//extern const NSInteger	JSServicesManagerInitialServicesCount;

extern	id		JSFindService( NSString* serviceName );

@interface JSServiceAbstract : NSResponder
{
	
}

+(id)sharedService;

-(NSString*)serviceName;
-(NSArray*)dependentServices;

-(id)initializeService;
-(void)openService;
-(void)closeService;

@end	//	JSServiceAbstract


@interface JSServiceManager : NSObject {

	IBOutlet	NSMutableArray*		activeServices;
		
}

+(id)sharedServices;

-(NSMutableArray*)activeServices;
-(id)findServiceWithName:(NSString*)serviceName;

-(void)initializeServices;
-(void)openServices;
-(void)closeServices;

@end	//	JSServiceManager

@interface NSApplication(JSServiceManagerExtensions)

-(JSServiceManager*)serviceManager;
-(void)initializeServiceManager;
-(void)openServiceManager;
-(void)closeServiceManager;

@end	//	NSApplication(JSServiceManagerExtensions)


