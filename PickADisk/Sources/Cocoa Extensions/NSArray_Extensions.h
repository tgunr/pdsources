#import <Foundation/Foundation.h>

@interface NSArray(MyExtensions)

-(BOOL)containsObjectIdenticalTo:(id)object;

-(NSArray*)arrayWithSubTrees;

-(NSArray*)arrayOfURLsFromPaths;
-(NSArray*)arrayOfPathsFromURLs;

-(NSArray*)arrayOfPathsThatConformToUTIs:(NSArray*)theUTIs resultsAsURL:(BOOL)saveURLs;

-(id)randomObject;

@end

@interface NSMutableArray(MyExtensions)

-(void)insertObjectsFromArray:(NSArray *)array atIndex:(NSInteger)index;

-(NSMutableArray*)reverseObjects;

@end

