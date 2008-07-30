#import "PADIndexProgressController.h"

@implementation PADIndexProgressController
static PADIndexProgressController* PADIndexProgressController_shared;

- (id)init
{
	if (PADIndexProgressController_shared) 
	{
        [self autorelease];
        return PADIndexProgressController_shared;
    }
    if (self = [super init])
	{	
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(taskDidEnd:)
													 name:NSTaskDidTerminateNotification
												   object:nil];
		PADIndexProgressController_shared = self;
	}
    return self; 
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[super dealloc];
}

- (void)awakeFromNib
{
	
	//[super awakeFromNib];
}

+ (id)shared
{
    if (!PADIndexProgressController_shared) {
        [[PADIndexProgressController alloc] init];
    }
    return PADIndexProgressController_shared;
}

- (IBAction)cancel:(id)sender
{
	if( taskAtHand )
		[taskAtHand terminate];
}

- (void)setPrimaryPromptString:(NSString*)text
{
	if( text == nil ) text = @"";
	if( primaryPrompt != nil ) [ primaryPrompt setStringValue:text ];
}

- (void)setSecondaryPromptString:(NSString*)text
{
	if( text == nil ) text = @"";
	if( secondaryPrompt != nil ) [ secondaryPrompt setStringValue:text ];
}

- (int)taskResult
{
	return taskResult; 
}

- (void)assignSheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{	
	[sheet orderOut:self];
	if( completionData == nil ) completionData = [self retain];
	if( completionTarget != nil )
		[completionTarget performSelectorOnMainThread:completionSelector withObject:completionData waitUntilDone:NO];
	if( completionData == self )
	{
		completionData = nil;
		[self release];
	}
	
	[self release];
}

- (id)startProgressDialogForTarget:(id)target finishSelector:(SEL)callback finishData:(id)data modalForWindow:(NSWindow*)parent withTask:(NSTask*)task
{
	completionTarget = target;
	completionSelector = callback;
	completionData = data;
	taskAtHand = task;
	
	if( progressWindow )
		[NSApp	beginSheet: progressWindow
		   modalForWindow: parent
			modalDelegate: self
		   didEndSelector: @selector(assignSheetDidEnd:returnCode:contextInfo:)
			  contextInfo: nil];
	
	if( taskAtHand )
		[taskAtHand launch];
	
	if( progressBar )
		[progressBar startAnimation:self];
	
	return self;
}

- (id)startProgressDialogForTarget:(id)target finishSelector:(SEL)callback finishData:(id)data modalForWindow:(NSWindow*)parent 
{
	return [self startProgressDialogForTarget:target finishSelector:callback finishData:data  modalForWindow:parent withTask:nil];
}

- (void)taskDidEnd:(NSNotification*)aNotice
{
	if( [aNotice object] != taskAtHand ) return;
	
	taskResult = [[aNotice object] terminationStatus];

	if( progressBar )
		[progressBar stopAnimation:self];

	[NSApp endSheet:progressWindow];
}

+ (id)runProgressDialogForTarget:(id)target finishSelector:(SEL)callback finishData:(id)data modalForWindow:(NSWindow*)parent withTask:(NSTask*)task
{
	return [[[PADIndexProgressController alloc] startProgressDialogForTarget:target
															  finishSelector:callback
																  finishData:data
															  modalForWindow:parent
																	withTask:task] autorelease];
}

+ (id)runProgressDialogForCommand:(NSString*)path arguments:(NSArray*)args forTarget:(id)target finishSelector:(SEL)callback modalForWindow:(NSWindow*)parent
{
	PADIndexProgressController*	doDialog = [PADIndexProgressController shared];
	NSTask*						doTask = [[[NSTask alloc] init] autorelease];
	
	if( !doDialog ) return( doDialog );
	self = doDialog;
	
	[doTask setLaunchPath:path];
	[doTask setArguments:args];
	
	return [doDialog startProgressDialogForTarget:target finishSelector:callback finishData:nil modalForWindow:parent withTask:doTask];
}


@end


