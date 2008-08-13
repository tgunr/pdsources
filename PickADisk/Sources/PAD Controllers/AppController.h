//
//  AppController.h

#import <Cocoa/Cocoa.h>
#import "PADAddVolumeController.h"
#import "TreeController.h"
#import "PADLayoutView.h"

void DACALSetup( void );

int		jPADBusyBodyBeat;			// Used internally as the counter for row spinning arrows

@interface AppController : NSObject {
	NSOperationQueue*		queue;
	NSMutableArray*			busyBodies;
	BOOL					busyBusy;
	TreeController*			dataView;
	PADIndexToolbarController*	toolbarController;
	IBOutlet id				addVolumeController;
}

+ (id)shared;
+ (void)playUISound:(NSInteger)theSound;
- (IBAction)provideFeedback:(id)sender;
- (void)queueOperation:(NSOperation*)op;

- (void)setDataView:(TreeController*)tc;
- (PADIndexToolbarController*)toolbarController;
- (void)setToolbarController:(PADIndexToolbarController*)tb;
- (IBAction)printReport:(id)sender;

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
