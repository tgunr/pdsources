//
//  PMTB_AppDelegate.m
//  PMTB
//
//  Created by Dave Carlton on 04/15/08.
//  Copyright PolyMicro Systems 2008 . All rights reserved.
//

#import "PMTB_AppDelegate.h"
#import "PMTB.h"
#import "PMTBFileSystem.h"
#import <MacFUSE/GMUserFileSystem.h>

@implementation PMTB_AppDelegate

- (void)awakeFromNib {
	NSLog(@"awakeFromNib");
}

/**
    Returns the support folder for the application, used to store the Core Data
    store file.  This code uses a folder named "PMTB" for
    the content, either in the NSApplicationSupportDirectory location or (if the
    former cannot be found), the system's temporary directory.
 */

- (NSString *)applicationSupportFolder {

    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
    NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : NSTemporaryDirectory();
    return [basePath stringByAppendingPathComponent:@"PMTB"];
}


/**
    Creates, retains, and returns the managed object model for the application 
    by merging all of the models found in the application bundle.
 */
 
- (NSManagedObjectModel *)managedObjectModel {

    if (managedObjectModel != nil) {
        return managedObjectModel;
    }
	
    managedObjectModel = [[NSManagedObjectModel mergedModelFromBundles:nil] retain];    
    return managedObjectModel;
}

 
/**
    Returns the persistent store coordinator for the application.  This 
    implementation will create and return a coordinator, having added the 
    store for the application to it.  (The folder for the store is created, 
    if necessary.)
 */

- (NSPersistentStoreCoordinator *) persistentStoreCoordinator {

    if (persistentStoreCoordinator != nil) {
        return persistentStoreCoordinator;
    }

    NSFileManager *fileManager;
    NSString *applicationSupportFolder = nil;
    NSURL *url;
    NSError *error;
    
    fileManager = [NSFileManager defaultManager];
    applicationSupportFolder = [self applicationSupportFolder];
    if ( ![fileManager fileExistsAtPath:applicationSupportFolder isDirectory:NULL] ) {
        [fileManager createDirectoryAtPath:applicationSupportFolder attributes:nil];
    }
    
    url = [NSURL fileURLWithPath: [applicationSupportFolder stringByAppendingPathComponent: @"PMTB.xml"]];
    persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel: [self managedObjectModel]];
    if (![persistentStoreCoordinator addPersistentStoreWithType:NSXMLStoreType configuration:nil URL:url options:nil error:&error]){
        [[NSApplication sharedApplication] presentError:error];
    }    

    return persistentStoreCoordinator;
}


/**
    Returns the managed object context for the application (which is already
    bound to the persistent store coordinator for the application.) 
 */
 
- (NSManagedObjectContext *) managedObjectContext {

    if (managedObjectContext != nil) {
        return managedObjectContext;
    }

    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil) {
        managedObjectContext = [[NSManagedObjectContext alloc] init];
        [managedObjectContext setPersistentStoreCoordinator: coordinator];
    }
    
    return managedObjectContext;
}


/**
    Returns the NSUndoManager for the application.  In this case, the manager
    returned is that of the managed object context for the application.
 */
 
- (NSUndoManager *)windowWillReturnUndoManager:(NSWindow *)window {
    return [[self managedObjectContext] undoManager];
}

/**
    Performs the save action for the application, which is to send the save:
    message to the application's managed object context.  Any encountered errors
    are presented to the user.
 */
 
- (IBAction) saveAction:(id)sender {

    NSError *error = nil;
    if (![[self managedObjectContext] save:&error]) {
        [[NSApplication sharedApplication] presentError:error];
    }
}

- (void) mountLoopbackFS {
	NSNotificationCenter* center = [NSNotificationCenter defaultCenter];
	[center addObserver:self selector:@selector(mountFailed:)
				   name:kGMUserFileSystemMountFailed object:nil];
	[center addObserver:self selector:@selector(didMount:)
				   name:kGMUserFileSystemDidMount object:nil];
	[center addObserver:self selector:@selector(didUnmount:)
				   name:kGMUserFileSystemDidUnmount object:nil];
	
	NSString* mountPath = @"/Volumes/PMTB";
	PMTBFileSystem* pmtb = [[PMTBFileSystem alloc] init];
	fs_ = [[GMUserFileSystem alloc] initWithDelegate:pmtb	isThreadSafe:YES];
	
	NSMutableArray* options = [NSMutableArray array];
	[options addObject:@"debug"];
	[options addObject:@"volname=PMTB"];
	[options addObject:
	 [NSString stringWithFormat:@"volicon=%@", 
	  [[NSBundle mainBundle] pathForResource:@"pmtb" ofType:@"icns"]]];
	
	[fs_ mountAtPath:mountPath withOptions:options];
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
//	NSOpenPanel* panel = [NSOpenPanel openPanel];
//	[panel setCanChooseFiles:NO];
//	[panel setCanChooseDirectories:YES];
//	[panel setAllowsMultipleSelection:NO];
//	int ret = [panel runModalForDirectory:@"~/Documents" file:nil types:nil];
//	if ( ret == NSCancelButton ) {
//		exit(0);
//	}
//	NSArray* paths = [panel filenames];
//	if ( [paths count] != 1 ) {
//		exit(0);
//	}
//	NSString* rootPath = [paths objectAtIndex:0];

//	if (myWindowController == NULL)
//		myWindowController = [[StorageWindowController alloc] initWithWindowNibName:@"MainWindow" owner:self];
//	
//	[myWindowController setDelegate: self];
//	NSWindow * mainWindow = [myWindowController window];	
//	[myWindowController showWindow: self];
}

/**
    Implementation of the applicationShouldTerminate: method, used here to
    handle the saving of changes in the application managed object context
    before the application terminates.
 */
 
- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender {

    NSError *error;
    int reply = NSTerminateNow;
    
    if (managedObjectContext != nil) {
        if ([managedObjectContext commitEditing]) {
            if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
				
                // This error handling simply presents error information in a panel with an 
                // "Ok" button, which does not include any attempt at error recovery (meaning, 
                // attempting to fix the error.)  As a result, this implementation will 
                // present the information to the user and then follow up with a panel asking 
                // if the user wishes to "Quit Anyway", without saving the changes.

                // Typically, this process should be altered to include application-specific 
                // recovery steps.  

                BOOL errorResult = [[NSApplication sharedApplication] presentError:error];
				
                if (errorResult == YES) {
                    reply = NSTerminateCancel;
                } 

                else {
					
                    int alertReturn = NSRunAlertPanel(nil, @"Could not save changes while quitting. Quit anyway?" , @"Quit anyway", @"Cancel", nil);
                    if (alertReturn == NSAlertAlternateReturn) {
                        reply = NSTerminateCancel;	
                    }
                }
            }
        } 
		else {
            reply = NSTerminateCancel;
        }
    }
    
	if (reply != NSTerminateCancel) {
		[[NSNotificationCenter defaultCenter] removeObserver:self];
		[fs_ unmount];
		id delegate = [fs_ delegate];
		[fs_ release];
		[delegate release];
		
	}		
    return reply;
}


/**
    Implementation of dealloc, to release the retained variables.
 */
 
- (void) dealloc {
    [managedObjectContext release], managedObjectContext = nil;
    [persistentStoreCoordinator release], persistentStoreCoordinator = nil;
    [managedObjectModel release], managedObjectModel = nil;
    [super dealloc];
}


@end

@implementation PMTB_AppDelegate (Notifications)

- (void)mountFailed:(NSNotification *)notification {
	NSLog(@"Got mountFailed notification.");
	NSDictionary* userInfo = [notification userInfo];
	NSError* error = [userInfo objectForKey:kGMUserFileSystemErrorKey];
	NSLog(@"kGMUserFileSystem Error: %@, userInfo=%@", error, [error userInfo]);  
	NSRunAlertPanel(@"Mount Failed", [error localizedDescription], nil, nil, nil);
	[[NSApplication sharedApplication] terminate:nil];
}

- (void)didMount:(NSNotification *)notification {
	NSLog(@"Got didMount notification.");
	NSDictionary* userInfo = [notification userInfo];
	NSString* mountPath = [userInfo objectForKey:kGMUserFileSystemMountPathKey];
	NSString* parentPath = [mountPath stringByDeletingLastPathComponent];
	[[NSWorkspace sharedWorkspace] selectFile:mountPath
					 inFileViewerRootedAtPath:parentPath];
}

- (void)didUnmount:(NSNotification*)notification {
	NSLog(@"Got didUnmount notification.");
	[[NSApplication sharedApplication] terminate:nil];
}

@end

@implementation PMTB_AppDelegate (PMTBUtil)

- (NSDictionary *)fetchData {
	NSLog(@"fetchData");
}

@end

