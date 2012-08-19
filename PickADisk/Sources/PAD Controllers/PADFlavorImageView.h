//
//  PADFlavorImageView.h
//  PickADisk
//
//  Copyright 2008 PolyMicro Systems. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "DACVolume.h"

@interface PADSimpleImageView : NSView {

	NSImage*				currentImage;
	CGFloat					currentAlpha;
	NSCompositingOperation	currentCompositingOp;
}

-(NSImage*)currentImage;
-(void)setCurrentImage:(NSImage*)newImage;
-(void)changeCurrentImage:(NSImage*)newImage;

-(CGFloat)currentAlpha;
-(void)setCurrentAlpha:(CGFloat)newAlpha;
-(void)changeCurrentAlpha:(CGFloat)newAlpha;

-(NSCompositingOperation)currentCompositingOp;
-(void)setCurrentCompositingOp:(NSCompositingOperation)newOp;
-(void)changeCurrentCompositingOP:(NSCompositingOperation)newOp;

-(BOOL)changeToNillImage;
-(BOOL)changeToDefaultImage;
-(BOOL)changeToIconRef:(IconRef)theIcon;
-(BOOL)changeToImageResource:(NSString*)imageName;

@end	//	PADSimpleImageView

@interface PADFlavorImageView : PADSimpleImageView

-(BOOL)changeToLibraryFlavor:(NSString*)flavorName;

@end	//	PADFlavorImageView

extern	const	CGFloat		kPADVIVStateRotateClockwise;
extern	const	CGFloat		kPADVIVStateRotateOff;
extern	const	CGFloat		kPADVIVStateRotateCounterClockwise;

@interface PADVolumeIconView : PADSimpleImageView
{
	CGFloat					currentRotation;
	
	CGFloat					spinsState;
	CGFloat					spinsPerSecond;
	NSTimer*				spinsTimer;
}

-(CGFloat)currentRotation;
-(void)setCurrentRotation:(CGFloat)newDegRotation;
-(void)changeCurrentRotation:(CGFloat)newDegRotation;
-(void)synchronizeRotation;

-(CGFloat)spinsState;
-(void)setSpinsState:(CGFloat)newState;
-(void)changeSpinsState:(CGFloat)newState;

-(void)changeSpinsPerSecond:(CGFloat)newRate;

-(void)spinUpInDirection:(CGFloat)spinDirection;
-(void)spinDown;

-(BOOL)changeToVolumeIcon:(DACVolume*)theVolume;

@end	//	PADVolumeIconView

@interface PADVolumeIconViewSpinAnimation : NSAnimation
{
	PADVolumeIconView*		theIcon;
}

+(void)runSpinForIcon:(PADVolumeIconView*)aniIcon spinUp:(BOOL)isStarting;
+(void)runSpinUpForIcon:(PADVolumeIconView*)aniIcon;

@end

@interface PADNamedImageView : PADSimpleImageView
{
	NSString*		resourceName;
	CGFloat			resourceAlpha;
}

-(NSString*)resourceName;
-(void)setResourceName:(NSString*)newName;
-(void)changeResourceName:(NSString*)newName;

-(CGFloat)resourceAlpha;
-(void)setResourceAlpha:(CGFloat)newAlpha;
-(void)changeResourceAlpha:(CGFloat)newAlpha;

@end	//	PADNamedImageView

