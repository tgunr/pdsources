//
//  PMTB_AppDelegate.h
//  PMTB
//
//  Created by Dave Carlton on 04/15/08.
//  Copyright PolyMicro Systems 2008 . All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "StorageWindowController.h"

@class GMUserFileSystem;
@class StorageWindowController;

@interface PMTB_AppDelegate : NSObject 
{
	GMUserFileSystem* fs_;
	StorageWindowController* myWindowController;
	
    NSPersistentStoreCoordinator *persistentStoreCoordinator;
    NSManagedObjectModel *managedObjectModel;
    NSManagedObjectContext *managedObjectContext;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator;
- (NSManagedObjectModel *)managedObjectModel;
- (NSManagedObjectContext *)managedObjectContext;

@end

@interface PMTB_AppDelegate (Notifications)

- (void)didMount:(NSNotification *)notification;
- (void)didUnmount:(NSNotification *)notification;

@end

@interface PMTB_AppDelegate (PMTBUtil)

- (NSDictionary *)fetchData;

@end

