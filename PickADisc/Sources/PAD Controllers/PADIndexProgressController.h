#import <Cocoa/Cocoa.h>

@interface PADIndexProgressController : NSObject {
    IBOutlet NSButton *cancelButton;
    IBOutlet id completionData;
    IBOutlet SEL completionSelector;
    IBOutlet id completionTarget;
    IBOutlet NSTextField *primaryPrompt;
    IBOutlet NSProgressIndicator *progressBar;
    IBOutlet NSWindow *progressWindow;
    IBOutlet NSTextField *secondaryPrompt;
    IBOutlet NSTask *taskAtHand;
    IBOutlet NSImageView *typeIcon;
	
	int	taskResult;
}

+ (id)shared;

- (IBAction)cancel:(id)sender;

- (void)setPrimaryPromptString:(NSString*)text;
- (void)setSecondaryPromptString:(NSString*)text;

- (int)taskResult;


- (id)startProgressDialogForTarget:(id)target finishSelector:(SEL)callback
						  finishData:(id)data									// passing nil will return the controller as the data
					  modalForWindow:(NSWindow*)parent
							withTask:(NSTask*)task;

- (id)startProgressDialogForTarget:(id)target finishSelector:(SEL)callback
						  finishData:(id)data
					  modalForWindow:(NSWindow*)parent;

+ (id)runProgressDialogForCommand:(NSString*)path
						arguments:(NSArray*)args
						forTarget:(id)target
				   finishSelector:(SEL)callback
				   modalForWindow:(NSWindow*)parent;

@end
