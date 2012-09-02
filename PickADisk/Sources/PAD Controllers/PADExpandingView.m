//
//  PADExpandingView.m
//  PickADisk
//
//  Copyright 2009 PolyMicro Systems. All rights reserved.
//

#import "PADExpandingView.h"


@implementation PADExpandingView

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
		disclosureOpen = YES;
		originalSize = frame.size;
		NSSize	closeIt = frame.size;
		closeIt.height = 24;
		closedSize = closeIt;
		
		if( [self autosaveValue] == NO )
			[self changeDisclosureOpen:NO withAnimation:NO];
    }
    return self;
}

- (void)drawRect:(NSRect)rect {
    // Drawing code here.
}

-(void)relocateRow:(float)newY
{
//	float	nextY = [self frame].size.height + newY;
	NSRect	newFrame = [self frame];
	
	newFrame.origin.y += newY;

	[self setFrame:newFrame];
	[nextView relocateRow:newY];
}

-(void)cascadeState:(BOOL)isOpen
{
	[self changeDisclosureOpen:isOpen withAnimation:YES];
	[nextView cascadeState:isOpen];
}

-(void)startCascade:(BOOL)isOpen
{
	id	theTop = topView;
	
	if( theTop == nil ) theTop = nextView;
	[theTop cascadeState:isOpen];
}

-(BOOL)disclosureOpen
{	return disclosureOpen;	}

-(void)setDisclosureOpen:(BOOL)isOpen
{	disclosureOpen = isOpen;	}

-(NSString*)autosaveNameKey
{	return [NSString stringWithFormat:@"PADMainInspectorView%i", [disclosureButton tag]];	}

-(BOOL)autosaveValue
{	
	if( [[NSUserDefaults standardUserDefaults] objectForKey:[self autosaveNameKey]] == nil )
		return YES;
	return [[NSUserDefaults standardUserDefaults] boolForKey:[self autosaveNameKey]];	
}

-(void)setAutosaveValue
{	[[NSUserDefaults standardUserDefaults] setBool:disclosureOpen forKey:[self autosaveNameKey]];	}

-(void)openToState:(BOOL)openState withAnimation:(BOOL)doAnim
{
	NSRect		myFrame = [self frame];
	NSWindow*	myWindow = [self window];
	NSSize		newSize = (openState == YES) ? originalSize : closedSize;
	float		thisOffset = thisOffset = myFrame.size.height - newSize.height;
	NSSize		maxSize, minSize;

	newSize.width = myFrame.size.width;
	
	[contentView setHidden:!openState];
	[self setFrameSize:newSize];
	
	if( doAnim == YES )
	{
	//	NSRect		theBottomFrame = [disclosureBottom frame];
	//	NSRect		theTabFrame = [self frame];
		NSRect		theWindowFrame = [myWindow frame];
	//	NSRect		theContentFrame = [myWindow contentRectForFrameRect:theWindowFrame];
	//	NSPoint		theNewSize; // = theTabFrame.size;
		
	//	float		theToolbarHeight = -(theWindowFrame.size.height - theContentFrame.size.height);
	//	float		theNewHeight = (theWindowFrame.size.height - (theTabFrame.size.height - theBottomFrame.origin.y)) + theToolbarHeight;
	//	float		theNewHeight = (theWindowFrame.size.height + thisOffset) + theToolbarHeight;
		float		theDeltaHeight = theWindowFrame.size.height - thisOffset;
		float		theDeltaOrigin = theWindowFrame.origin.y + thisOffset;
		
	//	theNewSize.x = theBottomFrame.size.width;
	//	theNewSize.y = theTabFrame.size.height - theBottomFrame.origin.y;
		
	//	theWindowFrame.size.width = theBottomFrame.size.width;
		theWindowFrame.size.height = theDeltaHeight; // theTabFrame.size.height - theBottomFrame.origin.y;
		theWindowFrame.origin.y = theDeltaOrigin;
		
		minSize.width = 300;
		minSize.height = theDeltaHeight;
		
		maxSize.width = 800;
		maxSize.height = theDeltaHeight;

		//[[tabView window] setContentSize:theWindowFrame.size];
		[self relocateRow:thisOffset];
		[myWindow setFrame:theWindowFrame display:YES animate:YES];
		[myWindow setMinSize:minSize];
		[myWindow setMaxSize:maxSize];
	//	[myWindow recalculateKeyViewLoop];
	} else {
		[self relocateRow:thisOffset];
	}
}

-(void)changeDisclosureOpen:(BOOL)isOpen withAnimation:(BOOL)doAnim
{
	[self setDisclosureOpen:isOpen];
	[disclosureButton setIntValue:(int)isOpen];
	[self setAutosaveValue];
	[self openToState:isOpen withAnimation:doAnim];
}

-(IBAction)clickDisclosureButton:(id)sender
{	
	BOOL	newState = ([sender state] == 1) ? YES : NO;
	BOOL	doCascade = ([[NSApp currentEvent] modifierFlags] & NSAlternateKeyMask) ? YES : NO;
	
	[self changeDisclosureOpen:newState withAnimation:YES];
	if( doCascade ) [self startCascade:newState];
}

@end
