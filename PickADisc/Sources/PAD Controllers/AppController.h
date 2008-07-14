//
//  AppController.h

#import <Cocoa/Cocoa.h>
#import "PADAddVolumeController.h"

void DACALSetup( void );

@interface AppController : NSObject {
	
}

+ (void)playUISound:(NSInteger)theSound;

@end
