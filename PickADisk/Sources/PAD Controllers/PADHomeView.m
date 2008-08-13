//
//  PADHomeView.m
//  PickADisk
//
//  Created by Jack Small on 8/9/08.
//  Copyright 2008 Jack Small. All rights reserved.
//

#import "PADHomeView.h"


@implementation PADHomeView

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    return self;
}

- (void)drawRect:(NSRect)rect {

	CGContextRef		viewContext = (CGContextRef)[[NSGraphicsContext currentContext] graphicsPort];
	CGRect				viewRect = NSRectToCGRect( rect );
																				//  0.804, 0.796, 0.722	  - sand
																				//  0.145, 0.263, 0.518	  - dkblue
																				//  0.188, 0.337, 0.671	  - ltblue
	CGContextSetRGBFillColor( viewContext, 0.742, 0.742, 0.742, 1.0 );			//  0.537, 0.584, 0.671    - versions
	CGContextFillRect( viewContext, viewRect );
	
}

@end
