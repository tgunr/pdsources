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

-(id)reverseObjects;

-(id)insertUniqueObjectsFromArray:(NSArray*)newArray atIndex:(NSInteger)index;
-(id)addUniqueObjectsFromArray:(NSArray*)newArray;

@end

