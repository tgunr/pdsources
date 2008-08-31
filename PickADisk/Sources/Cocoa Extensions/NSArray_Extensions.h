#import <Foundation/Foundation.h>

@interface NSArray(MyExtensions)
- (BOOL)containsObjectIdenticalTo:(id)object;
- (NSArray*) arrayWithSubTrees;
@end

@interface NSMutableArray(MyExtensions)
- (void)insertObjectsFromArray:(NSArray *)array atIndex:(NSInteger)index;
@end

