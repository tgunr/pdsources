//
//  PADHomeView.h
//  PickADisk
//
//  Copyright 2008 PolyMicro Systems. All rights reserved.
//

#import <Cocoa/Cocoa.h>

//  0.804, 0.796, 0.722	  - sand
//  0.145, 0.263, 0.518	  - dkblue
//  0.188, 0.337, 0.671	  - ltblue
//  0.537, 0.584, 0.671   - versions
//	0.742, 0.742, 0.742	  - grey*

#define		PADHomeView_DefaultColor_Red		0.742f
#define		PADHomeView_DefaultColor_Green		0.742f
#define		PADHomeView_DefaultColor_Blue		0.742f
#define		PADHomeView_DefaultColor_Alpha		1.000f

//	autumn_leaves.jpg
//	Camouflage0007_S.jpg
//	Camouflage0011_M.jpg
//	Camouflage0016_M.jpg
//	FullskiesAltostratus0007_M.jpg
//	Graid_blue.tif
//	Graid_gray.tif
//	Gray.tif*
//	Leather0048_M.jpg
//	Paper0015_M.jpg
//	Sepia Marble Paper.jpg
//	Threadplate0086_M.jpg
//	Threadplate0102_1_M.jpg
//	Various0213_M.jpg

#define		PADHomeView_DefaultImageFileName	@"Gray.tif"

CFAbsoluteTime		gPADHomeView_DefaultTimerTime	= 60.0 * 2;			// Default slide change every two minutes.  Override with pref "PADHomeViewDelay".

@interface PADHomeView : NSView
{
	NSColor*			backColor;
	NSImage*			backImage;
		
	BOOL				customBackground;
	
	NSMutableArray*		backImageList;
	NSTimer*			backImageTimer;
	
	NSURL*				currentURL;
}

-(NSImage*)backImage;
-(void)setBackImage:(NSImage*)newImage;

-(NSColor*)backColor;
-(void)setBackColor:(NSColor*)newColor;

-(BOOL)isCustomBackground;
-(void)setCustomBackground:(BOOL)isCustom;

-(NSMutableArray*)backImageList;
-(void)setBackImageList:(NSMutableArray*)newImageList;
-(BOOL)deleteBackImageURL:(NSURL*)oldURL;
-(BOOL)resetBackImageList;
-(NSInteger)backImageListCount;

-(NSURL*)currentURL;
-(void)setCurrentURL:(NSURL*)newURL;

-(void)resetBackground;
-(void)useDefaultBackground;
-(BOOL)isCustomUserBackground;

-(BOOL)saveBackImageList;
-(BOOL)loadBackImageList;

-(IBAction)randomBackground:(id)sender;
-(IBAction)deleteCurrentURL:(id)sender;
-(IBAction)restoreDefaultBackground:(id)sender;

@end
