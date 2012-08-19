//
//  PADExpandingView.h
//  PickADisk
//
//  Copyright 2009 PolyMicro Systems. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface PADExpandingView : NSView 
{
	IBOutlet	NSButton*			disclosureButton;
//	IBOutlet	NSBox*				disclosureBottom;
	IBOutlet	NSView*				contentView;
	IBOutlet	PADExpandingView*	topView;
	IBOutlet	PADExpandingView*	nextView;
	
	BOOL							disclosureOpen;
	NSSize							originalSize;
	NSSize							closedSize;
}

-(BOOL)autosaveValue;
-(void)openToState:(BOOL)openState withAnimation:(BOOL)doAnim;

-(void)relocateRow:(float)newY;
-(void)cascadeState:(BOOL)isOpen;

-(BOOL)disclosureOpen;
-(void)setDisclosureOpen:(BOOL)isOpen;
-(void)changeDisclosureOpen:(BOOL)isOpen withAnimation:(BOOL)doAnim;

-(IBAction)clickDisclosureButton:(id)sender;

@end
