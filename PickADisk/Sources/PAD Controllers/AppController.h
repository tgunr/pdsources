//
//  AppController.h

#import <Cocoa/Cocoa.h>
#import "PADAddVolumeController.h"
#import "TreeController.h"
#import "PADLayoutView.h"

int				jPADBusyBodyBeat;			// Used internally as the counter for row spinning arrows
BOOL			busyBusy;


@interface AppController : NSObject {
	NSOperationQueue*		queue;
	NSOperationQueue*		queueUI;
	NSOperationQueue*		queueSearch;
	NSMutableArray*			busyBodies;
//	BOOL					busyBusy;
	TreeController*			dataView;
	PADIndexToolbarController*	toolbarController;
	IBOutlet id				addVolumeController;
}

+ (id)shared;
+ (void)playUISound:(NSInteger)theSound;
+ (void)playUISoundForResult:(DACALResult)theResult;
+ (void)playUISoundForBOOL:(BOOL)wasSuccess;

- (IBAction)provideFeedback:(id)sender;			// Now unused - sent to prefs controller instead
//- (void)initCrashReport;
- (void)initPreferences;
- (void)queueOperation:(NSOperation*)op;
- (void)queueUIOperation:(NSOperation*)op;
- (void)queueSearchOperation:(NSOperation*)op;
- (void)cancelOperationsForDevice:(DACALDevice*)oldBox;

- (id)dataView;
- (void)setDataView:(TreeController*)tc;
- (PADIndexToolbarController*)toolbarController;
- (void)setToolbarController:(PADIndexToolbarController*)tb;

- (IBAction)addSlot:(id)sender;
- (IBAction)checkInOut:(id)sender;
- (IBAction)checkIn:(id)sender;
- (IBAction)checkOut:(id)sender;
- (IBAction)mountDisc:(id)sender;
- (IBAction)printReport:(id)sender;
- (IBAction)deleteSlot:(id)sender;
- (IBAction)idUnits:(id)sender;
- (IBAction)retractDoor:(id)sender;
- (IBAction)resetCarousel:(id)sender;
- (IBAction)gotoSlot:(id)sender;
- (IBAction)ejectVolumes:(id)sender;
- (IBAction)runLicense:(id)sender;
- (IBAction)requestLicense:(id)sender;

- (void)addBusyBody:(id)cell ofView:(id)view;
- (void)addBusyBody:(id)item;
- (void)removeBusyBody:(id)cell;
- (NSMutableArray*)busyBodies;
- (void)doBusyWork:(NSTimer*)busyTimer;

- (void)scheduledAddBusyBody:(NSTimer*)busyTimer;
- (void)scheduledRemoveBusyBody:(NSTimer*)busyTimer;

- (PADAddVolumeController*)addVolumeController;
- (void)setAddVolumeController:(PADAddVolumeController*)inAVC;
- (IBAction)runLicense:(id)sender;
- (IBAction)showHelp:(id)sender ;

@end
