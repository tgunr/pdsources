#import "PMTBDocument.h"

@implementation PMTBDocument

- (id)init 
{
    self = [super init];
    if (self != nil) {
        // initialization code
    }
    return self;
}


//- (id)initWithType:(NSString *)type error:(NSError **)error {
//    
//    self = [super initWithType:type error:error];
//    if (self != nil) {
//        // Insert an Occasion entity into the document
//        // We only want one Occasion ever inserted into a document. initWithType:error: is only called once per document,
//        // unlike init (which is called when opening saved documents as well as creating them for the first time). If we
//        // created the Occasion in init, we'd have to check to see if there was already an Occasion (e.g. with a Fetch Request)
//        // before inserting one. With initWithType:error: we do not need to check.
//		NSManagedObjectContext *managedObjectContext = [self managedObjectContext];
//        [NSEntityDescription insertNewObjectForEntityForName:@"DataStore" inManagedObjectContext:managedObjectContext];
//        // To avoid undo registration for this insertion we removeAllActions on the undoManager. We first call processPendingChanges
//        // on the managed object context to force the undo registration for this insertion, then call removeAllActions.
//        [managedObjectContext processPendingChanges];
//        [[managedObjectContext undoManager] removeAllActions];
//        [self updateChangeCount:NSChangeCleared];
//    }
//    return self;
//}

- (NSString *)windowNibName  {
    return @"PMTBDocument";
}

// Intercept validation errors with willPresentError: so that we can handle their display
- (NSError *)willPresentError:(NSError *)inError 
{
	// The error is a Core Data validation error if its domain is NSCocoaErrorDomain and it is between
	// the minimum and maximum for Core Data validation error codes.
	if ([[inError domain] isEqualToString:NSCocoaErrorDomain]) {
		int errorCode = [inError code];
		if ( errorCode >= NSValidationErrorMinimum && errorCode <= NSValidationErrorMaximum) {
			
			// If there are multiple validation errors, inError will be a NSValidationMultipleErrorsError
			// and all the validation errors will be in an array in the userInfo dictionary for key NSDetailedErrorsKey
			id detailedErrors = [[inError userInfo] objectForKey:NSDetailedErrorsKey];
			if (detailedErrors != nil) {
				
				// For this example we are only presenting the error messages for up to 3 validation errors at a time.
				// We are simply passing the NSLocalizedDescription for each error to the user, but one could instead
				// construct a customized, user-friendly error here. The error codes and userInfo dictionary
				// keys for validation errors are listed in <CoreData/CoreDataErrors.h>.
				
				unsigned numErrors = [detailedErrors count];							
				NSMutableString *errorString = [NSMutableString stringWithFormat:@"%u validation errors have occurred", numErrors];
				if (numErrors > 3)
					[errorString appendFormat:@".\nThe first 3 are:\n"];
				else
					[errorString appendFormat:@":\n"];
				
				unsigned i;
				for (i = 0; i < (numErrors > 3 ? 3 : numErrors); ++i) {
					[errorString appendFormat:@"%@\n", [[detailedErrors objectAtIndex:i] localizedDescription]];
				}
				
				NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithDictionary:[inError userInfo]];
				[userInfo setObject:errorString forKey:NSLocalizedDescriptionKey];
				
				return [NSError errorWithDomain:[inError domain] code:[inError code] userInfo:userInfo];
				
			} else {
				// As there is only one validation error, we are returning it verbatim to the user.
				return inError;
			}
		}
	}
	return inError;
}


- (void)windowControllerDidLoadNib:(NSWindowController *)windowController 
{
    [super windowControllerDidLoadNib:windowController];
    // user interface preparation code
}

@end
