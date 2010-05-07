//
//  PADLayoutView.m
//  PickADisk
//
//  Created by Jack Small on 8/2/08.
//  Copyright 2008 Jack Small. All rights reserved.
//

#import "PADLayoutView.h"
#import <Carbon/Carbon.h>

CFStringRef	CFStringCopyDateTime( CFAllocatorRef allocator, CFAbsoluteTime theTime, CFDateFormatterStyle dateForm, CFDateFormatterStyle timeForm );
CFStringRef	CFStringCopyDateTime( CFAllocatorRef allocator, CFAbsoluteTime theTime, CFDateFormatterStyle dateForm, CFDateFormatterStyle timeForm )
{
	CFDateRef			theDate = NULL;
	CFLocaleRef			thisLocale = CFLocaleCopyCurrent();
	CFDateFormatterRef	thisFormat = CFDateFormatterCreate( allocator, thisLocale, dateForm, timeForm );
	CFStringRef			thisDate = NULL;
	
	if( theTime == 0 ) theTime = CFAbsoluteTimeGetCurrent();
	theDate = CFDateCreate( allocator, theTime );
	
	if( theDate )
		thisDate = CFDateFormatterCreateStringWithDate( allocator, thisFormat, (CFDateRef)theDate );
	
	if( thisFormat != NULL ) CFRelease( thisFormat );
	if( thisLocale != NULL ) CFRelease( thisLocale );	
	if( theDate != NULL ) CFRelease( theDate );
	
	return thisDate;
}	

void	CFStringDrawInContext( CFStringRef drawWords, CGRect drawFrame, ThemeFontID drawFont, HIThemeTextHorizontalFlush hFlush, CGContextRef drawContext );
void	CFStringDrawInContext( CFStringRef drawWords, CGRect drawFrame, ThemeFontID drawFont, HIThemeTextHorizontalFlush hFlush, CGContextRef drawContext )
{
	CFMutableStringRef		slotTitle = NULL;
	HIThemeTextInfo			slotThemeInfo;
	
	slotTitle = CFStringCreateMutableCopy( kCFAllocatorDefault, 0, drawWords );

	slotThemeInfo.version = kHIThemeTextInfoVersionZero;
	slotThemeInfo.state = kThemeStateActive;
	slotThemeInfo.fontID = drawFont;
	slotThemeInfo.horizontalFlushness = hFlush;
	slotThemeInfo.verticalFlushness = kHIThemeTextVerticalFlushCenter;
	slotThemeInfo.options = 0;
	slotThemeInfo.truncationPosition = kHIThemeTextTruncationEnd;
	slotThemeInfo.truncationMaxLines = 1;
	slotThemeInfo.truncationHappened = FALSE;

	HIThemeDrawTextBox( slotTitle, &drawFrame, &slotThemeInfo, drawContext, kHIThemeOrientationNormal );

	CFRelease( slotTitle ), slotTitle = NULL;
}


@implementation PADLayoutView

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
		[self setReportBlankSlots: YES];
    }
    return self;
}

-(void)dealloc
{
	[self setReportDevice:(DACALDeviceRef)NULL];
	[super dealloc];
}

-(void)setReportDevice:(DACALDeviceRef)newDevice
{
	if( reportDevice == newDevice ) return;
	if( reportDevice != (DACALDeviceRef)NULL ) CFRelease( (CFTypeRef)reportDevice );
	if( newDevice != (DACALDeviceRef)NULL ) CFRetain( (CFTypeRef)newDevice );
	reportDevice = newDevice;
}

-(DACALDeviceRef)reportDevice
	{ return reportDevice; }

-(void)setReportBlankSlots:(BOOL)drawSlots
	{ reportBlankSlots = drawSlots; }

-(BOOL)reportBlankSlots
	{ return reportBlankSlots; }

- (BOOL)knowsPageRange:(NSRangePointer)range
{ 
	range->location = 1;
	range->length = 1;
	return YES; 
}

// Return the drawing rectangle for a particular page number
- (NSRect)rectForPage:(int)page { return [[NSPrintInfo sharedPrintInfo] imageablePageBounds]; }

- (NSPoint)locationOfPrintRect:(NSRect)aRect { return [[NSPrintInfo sharedPrintInfo] imageablePageBounds].origin; }

-(NSString*)printJobTitle
{
	if( reportDevice != (DACALDeviceRef)NULL ) return (NSString*)DACALCommandCopyName( reportDevice, NULL );
	else return [super printJobTitle];
}

- (NSAttributedString *)pageHeader
{
	NSAttributedString*		newHead = (NSAttributedString*)CFAttributedStringCreate( kCFAllocatorDefault, (CFStringRef)[self printJobTitle], NULL );
	return newHead;
}

- (void)drawRect:(NSRect)r {
	
	DACALSlotNum		slotCount = DACALCommandGetSlotCount( [self reportDevice] );
	DACALSlotNum		slotIndex = 0;
	
	NSRect				pageBound = [[NSPrintInfo sharedPrintInfo] imageablePageBounds];
	Boolean				pageLandscape = [[NSPrintInfo sharedPrintInfo] orientation] == NSLandscapeOrientation;
	
	CGFloat				totalWidth = pageBound.size.width;			// r.size.width;
	CGFloat				totalHeight = pageBound.size.height;		// r.size.height;
	CGFloat				gridHeight = totalHeight - 16.0;
	CGFloat				xOffset = 0.0;
	CGFloat				yOffset = 0.0;
	
	CGRect				titleRect;
	CFStringRef			titleString;
	
	CGColorRef			rowColor = NULL;
	int					rowPerColumn = pageLandscape ? 30 : 50;
	int					columnCount = (int)(slotCount / rowPerColumn);
	int					columnIndex = 0;
	
	CGFloat				columnGutter = pageLandscape ? 4.0 : 8.0;
	CGFloat				columnWidth = (totalWidth - (columnGutter*(columnCount-1))) / columnCount;
	
	CGFloat				slotGutter = 1.0;
	CGFloat				slotX, slotY;
	CGFloat				slotHeight = (gridHeight / rowPerColumn) - slotGutter;
	CGFloat				slotLine = 0.0;
	CGRect				slotRect;
	CFStringRef			slotName;
	CFStringRef			slotTitle;
	DACALSlotNum		slotNumber;
	
	CGContextRef		viewContext = (CGContextRef)[[NSGraphicsContext currentContext] graphicsPort];
	//NSMutableDictionary	*printDict = [[[NSPrintInfo sharedPrintInfo] printer] deviceDescription];
	
	//NSLog(@"PrintDict: %@", printDict);
	
	HIThemeBrushCreateCGColor( kThemeBrushListViewEvenRowBackground, &rowColor );
	
	// Translate into friendly coordinate system
	CGContextTranslateCTM( viewContext, pageBound.origin.x, totalHeight+pageBound.origin.y );
	CGContextScaleCTM( viewContext, 1, -1 );
		
    
	if ( [NSGraphicsContext currentContextDrawingToScreen] ) {
        // Draw screen-only elements here
    } else {
        // Draw printer-only elements here
    }
    // Draw common elements here
	
	// Draw Header
		
	titleRect = CGRectMake( xOffset, yOffset, totalWidth, 16.0 );
	
	titleString = DACALCommandCopyName( reportDevice, NULL );
	if( titleString ) {
		CGContextSetGrayStrokeColor( viewContext, 1.0, 1.0 );
		CFStringDrawInContext( titleString, titleRect, kThemeLabelFont, kHIThemeTextHorizontalFlushCenter, viewContext );
		CFRelease( titleString );
		titleString = NULL;
	}
	
	titleString = CFStringCopyDateTime( kCFAllocatorDefault, 0, kCFDateFormatterFullStyle, kCFDateFormatterNoStyle );
	if( titleString ) {
		CGContextSetGrayStrokeColor( viewContext, 0.5, 1.0 );
		CFStringDrawInContext( titleString, titleRect, kThemeSystemFontDetail, kHIThemeTextHorizontalFlushRight, viewContext );
		CFRelease( titleString );
		titleString = NULL;
	}
	
	yOffset += titleRect.size.height;
	
	// Draw Grid
	
	for( columnIndex=0; columnIndex < columnCount; columnIndex++ )
	{
		for( slotIndex=0; slotIndex < rowPerColumn; slotIndex++ )
		{
			slotX = (columnIndex*columnWidth)+(columnIndex*columnGutter);
			slotY = (slotIndex*slotHeight)+(slotIndex*slotGutter);
			slotRect = CGRectMake( xOffset + slotX, yOffset + slotY, columnWidth, slotHeight );

			slotNumber = slotIndex + (columnIndex*rowPerColumn)+1;
			slotName = DACALSlotCopyTitle( reportDevice, slotNumber, NULL );
			if( slotName == NULL ) slotName = CFSTR("");
			
			// Draw Line
			
			CGContextSaveGState( viewContext );
			CGContextSetStrokeColorWithColor( viewContext, rowColor );
			//CGContextSetGrayStrokeColor( viewContext, 0.82, 1.0 );
			CGContextSetLineCap( viewContext, kCGLineCapRound );
			
			slotLine = slotRect.origin.y + slotHeight - 1.0;
			CGContextMoveToPoint( viewContext, slotRect.origin.x, slotLine );
			CGContextAddLineToPoint( viewContext, slotRect.origin.x + columnWidth, slotLine );
			CGContextStrokePath( viewContext );
			
			CGContextRestoreGState( viewContext );
			
			// Draw Text
			
			slotTitle = CFStringCreateWithFormat( kCFAllocatorDefault, NULL, CFSTR("%3i\t%@"), (int)slotNumber, slotName );
			CGContextSetGrayStrokeColor( viewContext, 1.0, 1.0 );
			CFStringDrawInContext( slotTitle, slotRect, kThemeMiniSystemFont, kHIThemeTextHorizontalFlushLeft, viewContext );
			
			CFRelease( slotTitle ), slotTitle = NULL;
			CFRelease( slotName ), slotName = NULL;
		}
	}

}


+ (id)printReportForDevice:(DACALDeviceRef)box forSender:(id)sender
{
	NSRect			pageBound = [[NSPrintInfo sharedPrintInfo] imageablePageBounds];
	NSRect			pageRect = NSMakeRect(0.0, 0.0, pageBound.size.width+20, pageBound.size.height+60 ); //480.0, 640.0 ); 
	PADLayoutView	*newView = [[PADLayoutView alloc] initWithFrame:pageRect];
	
	[[NSPrintInfo sharedPrintInfo] setHorizontallyCentered:NO];
	[[NSPrintInfo sharedPrintInfo] setVerticallyCentered:NO];
	
	
	[newView setReportDevice:box];
	[newView print:sender];
	
	return newView;
}


@end
			
			
			
			
			
			
			
			
			
			
			
			
			
			
			
			
			
			
			
			
			
			
			
			
			
			
			
			
			
			
/* end */
			
			
			
			
			
			
			
			
			
			
			
			
			
			
