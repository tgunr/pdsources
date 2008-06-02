//
//  CarouselDocument.m
//  Carousel
//
//  Created by Dave Carlton on 05/16/08.
//  Copyright Polymicro Systems 2008 . All rights reserved.
//

#import "CarouselDocument.h"
#import "StorageWindowController.h"

@implementation CarouselDocument

//- (id)init 
//{
//    self = [super init];
//    if (self != nil) {
//        // initialization code
//    }
//    return self;
//}

- (id)initWithType:(NSString *)type error:(NSError **)error {
    
    self = [super initWithType:type error:error];
    if (self != nil) {
        // Insert an Occasion entity into the document
        // We only want one Occasion ever inserted into a document. initWithType:error: is only called once per document,
        // unlike init (which is called when opening saved documents as well as creating them for the first time). If we
        // created the Occasion in init, we'd have to check to see if there was already an Occasion (e.g. with a Fetch Request)
        // before inserting one. With initWithType:error: we do not need to check.
		NSManagedObjectContext *managedObjectContext = [self managedObjectContext];
        [NSEntityDescription insertNewObjectForEntityForName:@"DataStore" inManagedObjectContext:managedObjectContext];
        // To avoid undo registration for this insertion we removeAllActions on the undoManager. We first call processPendingChanges
        // on the managed object context to force the undo registration for this insertion, then call removeAllActions.
        [managedObjectContext processPendingChanges];
        [[managedObjectContext undoManager] removeAllActions];
        [self updateChangeCount:NSChangeCleared];
    }
    return self;
}

- (NSString *)windowNibName 
{
    return @"CarouselDocument";
}

- (void)windowControllerDidLoadNib:(StorageWindowController *)windowController 
{
    [super windowControllerDidLoadNib:windowController];
    // user interface preparation code
}

@end
