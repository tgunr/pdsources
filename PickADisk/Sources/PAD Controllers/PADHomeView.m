//
//  PADHomeView.m
//  PickADisk
//
//  Created by Jack Small on 8/9/08.
//  Copyright 2008 Jack Small. All rights reserved.
//

#import "PADHomeView.h"


@implementation PADHomeView

-(void)dealloc
{
	[self setBackImage:nil];
	[self setBackImageList:nil];
	[self setBackColor:nil];
	
	if( backImageTimer != nil )
	{
		[backImageTimer invalidate];
		backImageTimer = nil;
	}
	
	[super dealloc];
}

-(NSImage*)backImage
	{ return backImage; }

-(void)setBackImage:(NSImage*)newImage
{ 
	if( !backImage || ![backImage isEqual:newImage] )
	{
		if( newImage ) [newImage retain];
		if( backImage ) [backImage release];
		backImage = newImage;
	}
}

-(BOOL)isCustomBackground
	{ return customBackground; }

-(void)setCustomBackground:(BOOL)isCustom
	{ customBackground = isCustom; }

-(NSColor*)backColor
	{ return backColor; }

-(void)setBackColor:(NSColor*)newColor
{ 
	if( !backColor || ![backColor isEqual:newColor] )
	{
		if( newColor ) [newColor retain];
		if( backColor ) [backColor release];
		backColor = newColor;
	}
}

-(NSMutableArray*)backImageList
	{ return backImageList; }

-(void)setBackImageList:(NSMutableArray*)newImageList
{ 
	if( !backImageList || ![backImageList isEqual:newImageList] )
	{
		if( newImageList ) [newImageList retain];
		if( backImageList ) [backImageList release];
		backImageList = newImageList;
	}
}

-(BOOL)saveBackImageList
{
	BOOL				goodSave = NO;
	NSUserDefaults*		defaults = [NSUserDefaults standardUserDefaults];
	NSArray*			paths = [[self backImageList] arrayOfPathsFromURLs];
	
	[defaults setObject:paths forKey:@"PADHomeViewImages"];
	goodSave = [defaults synchronize];
	
	return goodSave;
}

-(BOOL)loadBackImageList
{
	BOOL				goodLoad = NO;
	NSMutableArray*		newList = [[NSMutableArray alloc] initWithCapacity:0];
	NSArray*			saveList = [[NSUserDefaults standardUserDefaults] objectForKey:@"PADHomeViewImages"];
	NSArray*			saveURLs = [saveList arrayOfURLsFromPaths];
	
	if( saveURLs != nil )
	{
		[newList addObjectsFromArray:saveURLs];
		[self setBackImageList:newList];
		[self setCustomBackground:YES];
		goodLoad = YES;
	}
	
	return goodLoad;
}

-(NSInteger)backImageListCount
{	
	if( backImageList == nil )
		return 0;
	else
		return [backImageList count];
}

-(void)useDefaultBackground
{
	[self setBackColor:[NSColor colorWithDeviceRed:PADHomeView_DefaultColor_Red
											 green:PADHomeView_DefaultColor_Green
											  blue:PADHomeView_DefaultColor_Blue
											 alpha:PADHomeView_DefaultColor_Alpha]];

	[self setBackImage:[NSImage imageNamed:PADHomeView_DefaultImageFileName]];
	[self setCustomBackground:( [self backImage] != nil )];
}

- (void)fireImageTimer:(NSTimer*)inTimer
{
	if( [self backImageListCount] > 1 )
	{
		[self setBackImage:nil];
		[self setNeedsDisplay:YES]; 
	}
}

- (id)initWithFrame:(NSRect)frame
{
    if( self = [super initWithFrame:frame] )
    {
		NSArray*	dropTypes = [NSArray arrayWithObjects: NSFilenamesPboardType, NSColorPboardType, nil];
		[self registerForDraggedTypes:dropTypes];
		
		if( ![self loadBackImageList] )
			[self useDefaultBackground];
		
		backImageTimer = [NSTimer scheduledTimerWithTimeInterval:gPADHomeView_DefaultTimerTime target:self selector:@selector(fireImageTimer:) userInfo:nil repeats:YES];
    }
    return self;
}

- (NSImage*)selectDrawImage
{
	NSImage*	outImage = [self backImage];
	NSURL*		workImage = nil;
	
	if( outImage == nil )
		if( [self backImageListCount] > 0 ) {
			workImage = [backImageList randomObject];
			outImage = [[NSImage alloc] initWithContentsOfURL:workImage];
			if( outImage != nil )
				[self setBackImage:outImage];
		}
	return outImage;
}

- (void)drawRect:(NSRect)rect
{
	NSImage*		drawImage = [self selectDrawImage];
	
	if( drawImage != nil )
		[drawImage drawInRect:rect fromRect:NSZeroRect operation:NSCompositeSourceAtop fraction:1.0];
	else 
	{
		[[self backColor] setFill];
		NSRectFill( rect );
	}
}

- (NSDragOperation)draggingSourceOperationMaskForLocal:(BOOL)isLocal
{
	NSDragOperation		outOper = NSDragOperationNone;
	
	if( !isLocal )
		outOper = NSDragOperationCopy || NSDragOperationLink || NSDragOperationGeneric;
	
	return outOper;
}

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender
{
    NSPasteboard*		pboard;
    NSDragOperation		sourceDragMask;
	NSArray*			testUTIs = [NSArray arrayWithObject:(NSString*)kUTTypeImage];
	
    sourceDragMask = [sender draggingSourceOperationMask];
    pboard = [sender draggingPasteboard];
	
    if ( [[pboard types] containsObject:NSColorPboardType] ) 
        if (sourceDragMask & NSDragOperationGeneric) 
            return NSDragOperationGeneric;
	
    if ( [[pboard types] containsObject:NSFilenamesPboardType] ) 
	{
		NSArray*	files = [pboard propertyListForType:NSFilenamesPboardType];
		NSArray*	matches = [files arrayOfPathsThatConformToUTIs:testUTIs resultsAsURL:YES];
		
		if( [matches count] > 0 ) 
			if (sourceDragMask & NSDragOperationLink) 
				return NSDragOperationLink;
			else if (sourceDragMask & NSDragOperationCopy)
				return NSDragOperationCopy;
    }
	
    return NSDragOperationNone;
}

-(BOOL)changeToColor:(NSColor*)newColor
{
	if( newColor == nil )
		[self useDefaultBackground];
	else
	{
		[self setBackColor:newColor];
		[self setCustomBackground:NO];
		[self setBackImage:nil];
	}
	
	[self setNeedsDisplay:YES];
	return YES;
}

-(BOOL)changeToImages:(NSMutableArray*)newImages
{
	if( newImages == nil )
		[self useDefaultBackground];
	else
	{
		[self setBackImageList:newImages];
		[self setCustomBackground:YES];
		[self setBackImage:nil];
	}
	
	[self saveBackImageList];
	[self setNeedsDisplay:YES];
	return YES;
}

-(BOOL)dropImageURLs:(NSArray*)theImages withOperation:(NSDragOperation)theOper
{
	BOOL				goodDrop = NO;
	NSMutableArray*		newImages = [[NSMutableArray alloc] initWithCapacity:0];
	
	//	If user specifies "copy" we add the new pictures to the existing list
	if( theOper & NSDragOperationCopy )
		if( [self backImageListCount] > 0 )
			[newImages addObjectsFromArray:[self backImageList]];
	
	if( theImages != nil )
		[newImages addObjectsFromArray:theImages];
		
	if( [newImages count] > 0 )
		goodDrop = [self changeToImages:newImages];
	
	return goodDrop;
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender
{
	BOOL				goodDrop = NO;
    NSPasteboard*		pboard;
    NSDragOperation		sourceDragMask;
	NSArray*			testUTIs = [NSArray arrayWithObject:(NSString*)kUTTypeImage];
	
    sourceDragMask = [sender draggingSourceOperationMask];
    pboard = [sender draggingPasteboard];
	
    if ( [[pboard types] containsObject:NSColorPboardType] )
	{
        // Only a copy operation allowed so just copy the data
		
        NSColor *newColor = [NSColor colorFromPasteboard:pboard];
        goodDrop = [self changeToColor:newColor];
	} 
	else if ( [[pboard types] containsObject:NSFilenamesPboardType] )
	{
        NSArray*	files = [pboard propertyListForType:NSFilenamesPboardType];
		NSArray*	matches = [files arrayOfPathsThatConformToUTIs:testUTIs resultsAsURL:YES];
		
		if( [matches count] > 0 ) 
			goodDrop = [self dropImageURLs:matches withOperation:sourceDragMask];
    }
	
    return goodDrop;
}





@end
