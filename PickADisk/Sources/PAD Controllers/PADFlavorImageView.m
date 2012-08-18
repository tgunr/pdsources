//
//  PADFlavorImageView.m
//  PickADisk
//
//  Created by Jack Small on 10/20/08.
//  Copyright 2008 Jack Small. All rights reserved.
//


@implementation PADSimpleImageView

-(void)dealloc
{
	[self setCurrentImage:nil];

	[currentImage release];
	[currentImage release];
	[super dealloc];
}

-(id)initSelfWithFrame:(NSRect)newFrame
{
	[self setCurrentCompositingOp:NSCompositeSourceOver];
	[self setCurrentAlpha:0.42];
	
	[self changeToDefaultImage];

	return self;
}

-(id)initWithFrame:(NSRect)newFrame
{
	if( self = [super initWithFrame:newFrame] )
		self = [self initSelfWithFrame:newFrame];
	
	return self;
}

-(NSImage*)currentImage
	{ return currentImage; }

-(void)setCurrentImage:(NSImage*)newImage
{
	if( !currentImage || ![currentImage isEqual:newImage] )
	{
		if( newImage ) [newImage retain];
		if( currentImage ) [currentImage retain];
		currentImage = newImage;
	}
}

-(void)changeCurrentImage:(NSImage*)newImage
{
	[self setCurrentImage:newImage];
	[self setNeedsDisplay:YES];
}

-(float)currentAlpha
	{ return currentAlpha; }

-(void)setCurrentAlpha:(float)newAlpha
{ 
	if( currentAlpha != newAlpha )
		currentAlpha = newAlpha;
}

-(void)changeCurrentAlpha:(float)newAlpha
{
	[self setCurrentAlpha:newAlpha];
	[self setNeedsDisplay:YES];
}

-(NSCompositingOperation)currentCompositingOp
	{ return currentCompositingOp; }

-(void)setCurrentCompositingOp:(NSCompositingOperation)newOp
	{ currentCompositingOp = newOp; }

-(void)changeCurrentCompositingOP:(NSCompositingOperation)newOp
{
	[self setCurrentCompositingOp:newOp];
	[self setNeedsDisplay:YES];
}

-(void)drawSelfBeginInRect:(NSRect)rect InContext:(CGContextRef)cgPort
{
	
}

-(void)drawSelfInRect:(NSRect)rect InContext:(CGContextRef)cgPort
{
	NSImage*		drawImage = [self currentImage];
	NSRect			drawRect = [self bounds];

	if( drawImage != nil )
		[drawImage drawInRect:drawRect fromRect:NSZeroRect operation:currentCompositingOp fraction:currentAlpha];
}

-(void)drawSelfFinishInRect:(NSRect)rect InContext:(CGContextRef)cgPort
{
	
}

-(void)drawRect:(NSRect)rect
{
	CGContextRef	cgPort = [[NSGraphicsContext currentContext] graphicsPort];
	
	[self drawSelfBeginInRect:rect	InContext:cgPort];
	[self drawSelfInRect:rect		InContext:cgPort];
	[self drawSelfFinishInRect:rect	InContext:cgPort];
}

-(BOOL)changeToNillImage
{
	[self changeCurrentImage:nil];
	return YES;
}

-(BOOL)changeToDefaultImage
{
	return [self changeToNillImage];
}

-(BOOL)changeToIconRef:(IconRef)theIcon
{
	if( theIcon == nil )
		return [self changeToNillImage];
	
	NSImage*	newImage = [[NSImage alloc] initWithIconRef:theIcon];
	BOOL		outGoodChange = (newImage != nil);

	if( newImage )
		[self changeCurrentImage:newImage];
	
	return outGoodChange;
}

-(BOOL)changeToImageResource:(NSString*)imageName
{
	if( imageName == nil )
		return [self changeToNillImage];
	
	NSImage*		newImage = [NSImage imageNamed:imageName];
	BOOL			didSwap = (newImage != nil);
	
	if( newImage )
		[self changeCurrentImage:newImage];
	
	return didSwap;
}

@end		//	PADSimpleImageView


@implementation PADFlavorImageView

-(BOOL)changeToDefaultImage
{
	[self setCurrentAlpha:0.42];
	[self setCurrentImage:[NSImage imageNamed:@"Generic_Files.icns"]];

	return YES;
}

-(BOOL)changeToLibraryFlavor:(NSString*)flavorName
{
	BOOL		outGoodChange = NO;
	NSString*	actualFlavor = DACALFlavorToFlavorValue( flavorName );
	NSString*	theImageFile = @"Generic_Files.icns";
	
	if( actualFlavor )
		if(	[actualFlavor isEqual:PADINDEX_FLAVORVALUE_FILES] )
			theImageFile = @"Generic_Files.icns";
		else if( [actualFlavor isEqual:PADINDEX_FLAVORVALUE_IMAGE] )
			theImageFile = @"Generic_Image.icns";
		else if( [actualFlavor isEqual:PADINDEX_FLAVORVALUE_MOVIE] )
			theImageFile = @"Generic_Movie.icns";
		else if( [actualFlavor isEqual:PADINDEX_FLAVORVALUE_MUSIC] )
			theImageFile = @"Generic_Music.icns";
	
	if( theImageFile )
		outGoodChange = [self changeToImageResource:theImageFile];
	
	return outGoodChange;
}

@end	//	PADFlavorImageView


//	PADVolumeIconView Spin States

const	CGFloat		kPADVIVStateRotateClockwise				= -1.0f;
const	CGFloat		kPADVIVStateRotateOff					= 0.0f;
const	CGFloat		kPADVIVStateRotateCounterClockwise		= 1.0f;

@implementation PADVolumeIconView

-(void)dealloc
{
	if( spinsTimer != nil )
		[spinsTimer invalidate];
	
	spinsTimer = nil;
	
	[super dealloc];
}

-(CGFloat)currentRotation
	{ return currentRotation; }

-(void)setCurrentRotation:(CGFloat)newDegRotation
	{ currentRotation = newDegRotation; }

-(void)changeCurrentRotation:(CGFloat)newDegRotation
{
	[self setCurrentRotation:newDegRotation];
	[self setNeedsDisplay:YES];
}

-(void)synchronizeRotation
{
//	CGFloat		currentAngle = currentRotation;
	CGFloat		deltaAngle = (0.10f * spinsPerSecond) * 360.0f;
	
	currentRotation += (deltaAngle * spinsState);
	if( currentRotation > 360.0f ) {
		currentRotation -= 360.0f;
	}
}

-(CGFloat)spinsState
	{ return spinsState; }

-(void)setSpinsState:(CGFloat)newState
	{ spinsState = newState; }

-(void)changeSpinsState:(CGFloat)newState
{
	[self setSpinsState:newState];
	[self setNeedsDisplay:YES];
}

-(void)changeSpinsPerSecond:(CGFloat)newRate
{
	spinsPerSecond = newRate;
	[self synchronizeRotation];
	[self display];
}

-(void)spinsTimerFired:(NSTimer*)theTimer
{
	[self synchronizeRotation];
	
	if( [self isHiddenOrHasHiddenAncestor] )
		return;
	
	if( currentImage && (spinsState != kPADVIVStateRotateOff) )
		[self setNeedsDisplay:YES];
}

-(id)initSelfWithFrame:(NSRect)newFrame
{
	if( self = [super initSelfWithFrame:newFrame] )
	{
		[self setCurrentRotation:0.0];
		spinsState = kPADVIVStateRotateOff;
		spinsPerSecond = 1.0f;
		
		NSTimer*	spinDr = [NSTimer scheduledTimerWithTimeInterval:0.10f
															  target:self
														    selector:@selector(spinsTimerFired:)
														    userInfo:nil
														     repeats:YES];
		spinsTimer = spinDr;
	}
	
	return self;
}

-(void)drawSelfBeginInRect:(NSRect)rect InContext:(CGContextRef)cgPort
{
	CGFloat			drawWidthHalf = ([self bounds].size.width / 2.0f);
	CGFloat			drawHeightHalf = ([self bounds].size.height / 2.0f) + 2;
	
	//	Rotate around center
	CGContextSaveGState( cgPort );
	CGContextTranslateCTM( cgPort, drawWidthHalf, drawHeightHalf );
	CGContextRotateCTM( cgPort, currentRotation * M_PI / 180.0f );
	CGContextTranslateCTM( cgPort, -drawWidthHalf, -drawHeightHalf );	
}

-(void)drawSelfFinishInRect:(NSRect)rect InContext:(CGContextRef)cgPort
{
	CGContextRestoreGState( cgPort );
}

-(BOOL)changeToDefaultImage
{
	BOOL	superChange = NO;
	
	if( superChange = [super changeToDefaultImage] )
	{
		[self setCurrentCompositingOp:NSCompositeSourceAtop];
		[self setCurrentAlpha:0.69];
	}
	
	return superChange;
}

-(void)spinUpInDirection:(CGFloat)spinDirection
{
	spinsPerSecond = 0.0;
	[PADVolumeIconViewSpinAnimation performSelector:@selector(runSpinUpForIcon:) withObject:(id)self afterDelay:0.5];
	//[self setSpinsState:spinDirection];
	//[PADVolumeIconViewSpinAnimation runSpinForIcon:self spinUp:YES];
	//spinsPerSecond = 1.0;
}

-(void)spinDown
{
	[PADVolumeIconViewSpinAnimation runSpinForIcon:self spinUp:NO];
	[self changeSpinsState:kPADVIVStateRotateOff];
//	[self changeCurrentRotation:0.0];
}

-(BOOL)changeToVolumeIcon:(DACVolume*)theVolume
{
	[self changeCurrentRotation:0.0];

	return [self changeToIconRef:[theVolume mediaIcon]]; 
}

@end	//	PADVolumeIconView

@implementation PADVolumeIconViewSpinAnimation

-(void)dealloc
{
	theIcon = nil;
	[super dealloc];
}

-(id)initSpinForIcon:(PADVolumeIconView*)aniIcon onCurve:(NSAnimationCurve)theCurve
{
	if( self = [super initWithDuration:1.0 animationCurve:theCurve] )
	{
		theIcon = aniIcon;
		[self setFrameRate:20.0];
	}
	return self;
}

- (void)setCurrentProgress:(NSAnimationProgress)progress
{
    // Call super to update the progress value.
    [super setCurrentProgress:progress];

	[theIcon changeSpinsPerSecond:[self currentValue]];
}

+(void)runSpinForIcon:(PADVolumeIconView*)aniIcon spinUp:(BOOL)isStarting
{
	NSAnimationCurve					theCurve = isStarting ? NSAnimationEaseIn : NSAnimationEaseOut;
	PADVolumeIconViewSpinAnimation*		goAni = [[PADVolumeIconViewSpinAnimation alloc] initSpinForIcon:aniIcon onCurve:theCurve];
	
	[goAni startAnimation];
	[goAni release];
}

+(void)runSpinUpForIcon:(PADVolumeIconView*)aniIcon
{
	[aniIcon setSpinsState:kPADVIVStateRotateClockwise];
	[PADVolumeIconViewSpinAnimation runSpinForIcon:aniIcon spinUp:YES];
}

@end	//	PADVolumeIconViewSpinAnimation

@implementation PADNamedImageView

-(id)initSelfWithFrame:(NSRect)newFrame
{
	resourceAlpha = 0.42;
	resourceName = @"PAD4.icns";
	
	return [super initSelfWithFrame:newFrame];
}

-(BOOL)loadResourceImage
{
	CGFloat		newAlpha = [self resourceAlpha];
	NSString*	newName = [self resourceName];
	BOOL		newImage = (newName != nil);
	
	if( newImage ) {
		[self setCurrentAlpha:newAlpha];
		[self setCurrentImage:[NSImage imageNamed:newName]];
	}
	
	return newImage;
}

-(BOOL)changeToDefaultImage
	{ return [self loadResourceImage]; }

-(NSString*)resourceName
	{ return resourceName; }

-(void)setResourceName:(NSString*)newName
{
	if( !resourceName || ![resourceName isEqual:newName] )
	{
		if( newName ) [newName retain];
		if( resourceName ) [resourceName release];
		resourceName = newName;
	}	
}

-(void)changeResourceName:(NSString*)newName
{
	[self setResourceName:newName];
	[self loadResourceImage];
	[self setNeedsDisplay:YES];
}


-(CGFloat)resourceAlpha
{ return resourceAlpha; }

-(void)setResourceAlpha:(CGFloat)newAlpha
	{ resourceAlpha = newAlpha; }

-(void)changeResourceAlpha:(CGFloat)newAlpha 
{
	[self setResourceAlpha:newAlpha];
	[self setCurrentAlpha:newAlpha];
	[self setNeedsDisplay:YES];
}

- (void)dealloc {
	[resourceName release];
	[super dealloc];
}

@end



