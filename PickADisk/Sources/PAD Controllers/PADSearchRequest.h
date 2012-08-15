//
//  PADSearchRequest.h
//  PickADisc
//
//  Copyright 2008 PolyMicro Systems. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "JSServiceManager.h"
#import "AppController.h"
#import "SimpleTreeNode.h"

typedef float		PADSearchRelevance;
typedef NSNumber*	PADSearchRelevanceRef;

extern const	NSString*			kPADSearchByTitle;
extern const	NSString*			kPADSearchByTitleID;
extern const	NSString*			kPADSearchByType;
extern const	NSString*			kPADSearchByTypeID;
extern const	NSString*			kPADSearchByDateAdded;
extern const	NSString*			kPADSearchByDateAddedID;
extern const	NSString*			kPADSearchByFileUTI;
extern const	NSString*			kPADSearchByFileUTIID;

typedef enum PADSearchConjunction {
	kPADSearchConjunctionOr		= ( 1 << 0 ),
	kPADSearchConjunctionAnd	= ( 1 << 1 ),
	kPADSearchConjunctionNot	= ( 1 << 2 ),
	kPADSearchConjunctionNormal	= kPADSearchConjunctionOr
} PADSearchConjunction;

extern const	PADSearchRelevance	kPADSearchWeightNormal;
extern const	PADSearchRelevance	kPADSearchWeightHalf;
extern const	PADSearchRelevance	kPADSearchWeightNone;

extern const	NSString*			kPADSearchOptionResultType;
extern const	NSString*			kPADSearchOptionResultTypeLeaf;
extern const	NSString*			kPADSearchOptionResultTypeItem;

@interface PADSearchTerm : NSObject {

	NSString*				termTitle;
	NSString*				termID;
	int						termOrder;
	PADSearchConjunction	termConjuntion;
	float					termWeight;
	id						termCompareDataValue;
	SEL						termGetDataSelector;
	SEL						termCompareDataSelector;

	NSMutableDictionary*	termOptions;
}

- (NSString*)termTitle;
- (void)setTermTitle:(NSString*)title;

- (NSString*)termID;
- (void)setTermID:(NSString*)id;

- (int)termOrder;
- (void)setTermOrder:(int)id;

- (PADSearchConjunction)termConjuntion;
- (void)setTermConjunction:(PADSearchConjunction)newConjunction;

- (float)termWeight;
- (void)setTermWeight:(float)weight;

- (id)compareData;
- (void)setCompareData:(id)data;

- (SEL)getSelector;
- (void)setGetSelector:(SEL)data;

- (SEL)compareSelector;
- (void)setCompareSelector:(SEL)data;

- (NSMutableDictionary*)termOptions;
- (void)setTermOptions:(NSMutableDictionary*)options;

- (PADSearchRelevance)compareWithElement:(id)element;
- (PADSearchRelevance)compareForSearch:(id)value withOptions:(NSMutableDictionary*)options;

- (PADSearchTerm*)initWithTitle:(NSString*)title termID:(NSString*)newID getSelector:(SEL)getSel compareSelector:(SEL)cmpSel compareData:(id)data andOptions:(NSDictionary*)options;
- (PADSearchTerm*)termWithTerm;

+ (PADSearchTerm*)termWithTitle:(NSString*)title termID:(NSString*)newID getSelector:(SEL)getSel compareSelector:(SEL)cmpSel compareData:(id)data andOptions:(NSDictionary*)options;
	
@end		// PADSearchTerm

//	This function should be called during initialization to setup the search categories
//void			PADSearchTermSetup();

//	This function is called during setup to create known search terms
//void			PADAddSearchTerm( const NSString* title, const NSString* newID, SEL getSel, SEL cmpSel, id data, NSDictionary* options );

//	This function is called internally in PADSearchRequest -createTermsForKeys to create local copies of search terms.
//PADSearchTerm*	PADCopySearchTermWithTitleOrID( NSString* aTitle );


@interface PADSearchRequest : NSObject {

	NSArray*				searchLocations;
	NSMutableDictionary*	searchTermDictionary;
	NSMutableArray*			searchTermElements;
	NSMutableArray*			searchTermOperations;
	NSMutableDictionary*	searchOptions;
	
	BOOL					searchingNow;
	BOOL					searchResultsDirty;
	int						searchError;
	NSMutableArray*			searchResults;
	
	id						searchTarget;
	id						searchNode;
	id						searchSubTree;
	NSMutableArray*			searchTermParents;
	
	NSArray*				searchOriginalSelection;
}

// This function is used to add terms to a search.  Unrecognized terms are ignored during the search.
// order is a positive integer reperesenting the absolute order of term evaluation, or one of the constants with a logical value
// weight is expressed as a percentile where 1.0 = 100% *for each term*. 
// Match "scores" are expressed as a relative percentage of the maximum score possible.
-(void)addSearchTerm:(id)inTerm forValue:(id)inValue inOrder:(int)order andConjunction:(PADSearchConjunction)inConj withWeight:(float)weight andOptions:(NSDictionary*)inOptions;

// This function is used to start a search.
// Targets creating searches are expected to respond to the following selectors:
//
// - (void)searchFoundResults:(NSArray*)itemsFound forSearch:(PADSearchRequest*)theSearch
// - (void)searchCompleted:(PADSearchRequest*)theSearch
//
// Note that any returned itemsFound are already attached as children to subTree if one is provided.
//
-(PADSearchRequest*)setupSearchForTarget:(id)target onNode:(id)node andSubTree:(id)subTree;
-(PADSearchRequest*)startSearch;

-(SimpleTreeNode*)resultsSubTree;
-(NSMutableDictionary*)searchTermDictionary;
-(id)searchTarget;
-(BOOL)searchBusy;
-(id)valueForTerm:(id)term;

-(BOOL)searchResultsDirty;
-(void)dirtySearchResults;

-(NSArray*)searchOriginalSelection;
-(void)setSearchOriginalSelection:(NSArray*)selection;

// Called internally
-(void)createTermsForKeys;
-(void)searchDataChanged:(NSArray*)theItems;

// Used to setup a new search.  If inLocs == nil, then the subTrees of all the mounted devices are used.
-(id)initSearchInLocations:(NSArray*)inLocs andOptions:(NSDictionary*)inOptions;

+(id)searchCarouselsForStars:(NSString*)inUTI resultType:(const NSString*)inType;
+(id)searchCarouselsForFileUTI:(NSString*)inUTI resultType:(const NSString*)inType;
+(id)searchCarouselsForDateAddedBeforeDays:(NSTimeInterval)inDays ofDate:(id)inDate resultType:(const NSString*)inType;
+(id)searchCarouselsForCheckedInOutBeforeDays:(NSTimeInterval)inDays ofDate:(id)inDate resultType:(const NSString*)inType;
+(id)searchCarouselsForKind:(NSString*)inTerm resultType:(const NSString*)inType;
+(id)searchCarouselsForTitle:(NSString*)inKind resultType:(const NSString*)inType;
+(id)searchCarouselsForTerm:(NSString*)inTerm;

@end	// PADSearchRequest

@interface PADSearchTermOperation : NSOperation
{
	SimpleTreeNode*	searchTree;
	NSArray*		searchTerms;
	BOOL			searchBusy;
	
	NSMutableArray*	inQueue;
	NSMutableArray*	matchQueue;
	NSMutableArray* parentQueue;
	
	id				messageTarget;
}

-(BOOL)searchDone;
-(BOOL)searchBusy;
-(BOOL)elementsWaiting;

-(NSArray*)pullMatchQueue;
-(id)parentMatchOfChildMatch:(SimpleTreeNode*)child;

-(void)endSearch;
-(void)startSearch;

-(PADSearchTermOperation*)initWithTree:(SimpleTreeNode*)aTree forTerms:(NSArray*)theTerms andTarget:(id)aTarget;
-(void)notifyTarget:(BOOL)done;

+(PADSearchTermOperation*)searchOperationsForTreeNode:(SimpleTreeNode*)rootSubTree forTerms:(NSArray*)theTerms andTarget:(id)aTarget;

@end	// PADSearchTermOperation

@interface PADSearchService : JSServiceAbstract
{
	NSMutableArray*		searchTerms;
	
	NSMutableArray*		activeSearches;
	NSMutableArray*		activeWatchers;
}

+(id)sharedSearch;
+(void)updateAllSearches;

-(void)addSearchTermWithTitle:(const NSString*)title
					andTermID:(const NSString*)newID
				  getSelector:(SEL)getSel
			  compareSelector:(SEL)cmpSel
				  compareData:(id)data
				   andOptions:(NSDictionary*)options;

-(PADSearchTerm*)copySearchTermWithTitleOrID:(NSString*)aTermName;

-(void)addActiveSearch:(PADSearchRequest*)newRequest;
-(void)removeActiveSearch:(PADSearchRequest*)oldRequest;

-(void)addActiveWatcher:(id)newWatcher;
-(void)removeActiveWatcher:(id)oldWatcher;

-(void)searchStarted:(PADSearchRequest*)aRequest;
-(void)searchFinished:(PADSearchRequest*)aRequest;
-(void)searchDataChanged:(NSArray*)theItems;

@end	// PADSearchService

@interface SearchNodeData : SimpleNodeData
{
	SimpleTreeNode*		matchActual;
	PADSearchRelevance	matchScore;
}

-(SimpleTreeNode*)matchActual;
-(PADSearchRelevance)matchScore;

-(id)initWithLocationOfActual:(SimpleTreeNode*)inMatch withScore:(PADSearchRelevance)inScore asResult:(NSString*)resultType;
+(id)nodeDataWithLocationOfActual:(SimpleTreeNode*)inMatch withScore:(PADSearchRelevance)inScore asResult:(NSString*)resultType;

@end	// SearchNodeData

@interface SimpleTreeNode(PADSearchExtensions)

-(SimpleNodeData*)keyScore;

-(id)initForActualMatch:(SimpleTreeNode*)aMatch withScore:(PADSearchRelevance)aScore asResult:(NSString*)resultType;
+(id)treeForActualMatch:(SimpleTreeNode*)aMatch withScore:(PADSearchRelevance)aScore asResult:(NSString*)resultType;

@end	// SimpleTreeNode(PADSearchExtensions)




