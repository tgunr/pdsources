//
// Created by davec on 8/19/12.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import <Cocoa/Cocoa.h>
#import <DACAL/dacallib.h>

@class DACALDevice;
@class SimpleTreeNode;
@class DACVolume;
@class DACALSlotElement;

@interface DACALSlot : NSObject {

	DACALDevice*		slotDevice;
	DACALSlotNum		slotNumber;

	SimpleTreeNode*		slotNode;
	DACVolume*			slotVolume;
	FSRef				slotFSRef;

	NSString*			slotIdentifier;

	BOOL				slotIsCheckedOut;
	NSDate*				slotCheckedOut;
	NSDate*				slotCheckedIn;

	NSMutableArray*		slotElements;
}

-(DACALDevice*)slotDevice;
-(DACALDeviceRef)slotDeviceRef;
-(DACALSlotNum)slotNumber;
-(SimpleTreeNode*)slotNode;
-(DACVolume*)slotVolume;
-(FSRef*)slotFSRef;
-(BOOL)validSlotFSRef;
-(BOOL)setSlotFSRefFromURL:(NSURL*)slotURL;
-(BOOL)setSlotLocation:(NSURL*)slotURL;

//- (NSUndoManager*)undoManager;

-(NSMutableArray*)slotElements;
-(void)setSlotElements:(NSMutableArray*)newElements;
-(void)addSlotElement:(DACALSlotElement*)newElement;
-(void)removeSlotElement:(DACALSlotElement*)oldElement;

-(DACALSlotElement*)elementWithFSRef:(const FSRef*)otherFSRef;
-(DACALSlotElement*)elementWithURL:(NSURL*)otherURL;

-(NSString*)slotIdentifier;
-(void)setSlotIdentifier:(NSString*)newID;
-(DACALSlot*)slotWithIdentifier:(NSString*)slotID;

-(id)initSlotForDevice:(DACALDevice*)newDevice inSlot:(DACALSlotNum)newSlot;
+(id)slotForDevice:(DACALDevice*)newDevice inSlot:(DACALSlotNum)newSlot;

-(void)reloadSlot;
-(void)reloadElement:(DACALSlotElement*)theElement;

-(void)swapWithSlot:(DACALSlot*)otherSlot;

-(NSString*)title;
-(NSString*)displayTitle;
-(NSURL*)fileURL;

-(NSString*)flavor;
-(void)setFlavor:(NSString*)newFlavor;

-(DACALResult)moveDeviceToSlotWithOptions:(DACALOptionBits)slotOptions;

+(BOOL)moveDevicesToSlotsOfNodes:(NSArray*)theTreeNodes;
+(BOOL)ejectSlotVolumesOfNodes:(NSArray*)theTreeNodes;

-(BOOL)isCheckedOut;
-(void)setIsCheckedOut:(BOOL)isOut;

-(NSDate*)checkedOutDate;
-(void)setCheckedOutDate:(NSDate*)newDate;

-(NSDate*)checkedInDate;
-(void)setCheckedInDate:(NSDate*)newDate;

-(NSDictionary*)currentReservation;
-(NSDictionary*)reservationHistory;

-(BOOL)checkOutForUser:(NSString*)userName onHost:(NSString*)userHost withUI:(BOOL)doUI;
-(BOOL)checkInForUser:(NSString*)userName onHost:(NSString*)userHost withUI:(BOOL)doUI;
-(BOOL)toggleReservationForUser:(NSString*)userName	onHost:(NSString*)userHost withUI:(BOOL)doUI;

-(BOOL)isSlotMounted;
-(NSString*)slotHost;
-(BOOL)slotMountedAsVolume:(DACVolume*)mountVolume;
-(BOOL)slotUnmounted;

-(BOOL)isSlotAssigned;
-(BOOL)slotAssignedIndexFromVolume:(DACVolume*)indexVolume asType:(NSString*)newType;
-(BOOL)unassignSlotIndex;

-(NSNumber*)volumeSize;

@end		//	DACALSlot
