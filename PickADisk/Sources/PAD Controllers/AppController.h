//
//  AppController.h

#import <Cocoa/Cocoa.h>
#import "PADAddVolumeController.h"
#import "TreeController.h"
#import "PADLayoutView.h"


int				jPADBusyBodyBeat;			// Used internally as the counter for row spinning arrows
BOOL			busyBusy;

void DACALNotification( void* inData, DACALDeviceRef inBox, CFStringRef inMessage, CFDictionaryRef inParam );
void DACALSetup( void );


@interface AppController : NSObject {
	NSOperationQueue*		queue;
	NSOperationQueue*		queueUI;
	NSMutableArray*			busyBodies;
//	BOOL					busyBusy;
	TreeController*			dataView;
	PADIndexToolbarController*	toolbarController;
	IBOutlet id				addVolumeController;
}

+ (id)shared;
+ (void)playUISound:(NSInteger)theSound;
+ (void)playUISoundForResult:(DACALResult)theResult;

- (IBAction)provideFeedback:(id)sender;			// Now unused - sent to prefs controller instead
- (void)queueOperation:(NSOperation*)op;
- (void)queueUIOperation:(NSOperation*)op;

- (void)setDataView:(TreeController*)tc;
- (PADIndexToolbarController*)toolbarController;
- (void)setToolbarController:(PADIndexToolbarController*)tb;

- (IBAction)addSlot:(id)sender;
- (IBAction)checkInOut:(id)sender;
- (IBAction)mountDisc:(id)sender;
- (IBAction)printReport:(id)sender;
- (IBAction)deleteSlot:(id)sender;
- (IBAction)idUnits:(id)sender;
- (IBAction)retractDoor:(id)sender;
- (IBAction)resetCarousel:(id)sender;

-(void)deviceAttached:(DACALDeviceRef)newBox;
-(void)deviceDetached:(DACALDeviceRef)oldBox;

- (void)addBusyBody:(id)cell ofView:(id)view;
- (void)addBusyBody:(id)item;
- (void)removeBusyBody:(id)cell;
- (NSMutableArray*)busyBodies;
- (void)doBusyWork:(NSTimer*)busyTimer;

- (void)scheduledAddBusyBody:(NSTimer*)busyTimer;
- (void)scheduledRemoveBusyBody:(NSTimer*)busyTimer;

- (PADAddVolumeController*)addVolumeController;
- (void)setAddVolumeController:(PADAddVolumeController*)inAVC;

@end
