/*
    NSArray_Extensions.m
    Copyright (c) 2001-2006, Apple Computer, Inc., all rights reserved.
    Author: Chuck Pisula

    Milestones:
    * 03-01-2001: Initial creation by Chuck Pisula

    NSArray and NSMutableArray categories (MyExtensions).
*/

/*
 IMPORTANT:  This Apple software is supplied to you by Apple Computer, Inc. ("Apple") in
 consideration of your agreement to the following terms, and your use, installation, 
 modification or redistribution of this Apple software constitutes acceptance of these 
 terms.  If you do not agree with these terms, please do not use, install, modify or 
 redistribute this Apple software.
 
 In consideration of your agreement to abide by the following terms, and subject to these 
 terms, Apple grants you a personal, non-exclusive license, under Apple’s copyrights in 
 this original Apple software (the "Apple Software"), to use, reproduce, modify and 
 redistribute the Apple Software, with or without modifications, in source and/or binary 
 forms; provided that if you redistribute the Apple Software in its entirety and without 
 modifications, you must retain this notice and the following text and disclaimers in all 
 such redistributions of the Apple Software.  Neither the name, trademarks, service marks 
 or logos of Apple Computer, Inc. may be used to endorse or promote products derived from 
 the Apple Software without specific prior written permission from Apple. Except as expressly
 stated in this notice, no other rights or licenses, express or implied, are granted by Apple
 herein, including but not limited to any patent rights that may be infringed by your 
 derivative works or by other works in which the Apple Software may be incorporated.
 
 The Apple Software is provided by Apple on an "AS IS" basis.  APPLE MAKES NO WARRANTIES, 
 EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, 
 MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS 
 USE AND OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
 
 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL OR CONSEQUENTIAL 
 DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS 
 OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, 
 REPRODUCTION, MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED AND 
 WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE), STRICT LIABILITY OR 
 OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

#import "NSArray_Extensions.h"

@implementation NSArray (MyExtensions)

-(BOOL)containsObjectIdenticalTo: (id)obj { 
    return [self indexOfObjectIdenticalTo: obj]!=NSNotFound; 
}

-(NSArray*)arrayWithSubTrees
{
	int		aIndex, aCount = [self count];
	NSMutableArray*		workArray = [NSMutableArray arrayWithCapacity:256];
	NSArray*			outArray = nil;
	
	for( aIndex=0; aIndex < aCount; aIndex++ )
		[workArray addObject:[[[self objectAtIndex:aIndex] nodeData] subTree]];

	outArray = [NSArray arrayWithArray:workArray];
	return outArray;
}

-(NSArray*)arrayOfURLsFromPaths
{
	NSInteger		pathCount = [self count];
	NSInteger		index = 0;
	NSMutableArray*	urlArray = [NSMutableArray arrayWithCapacity:pathCount];
	NSURL*			workURL = nil;
	NSArray*		outArray = nil;
	
	//	Create array of urls from array of paths
	for( index=0; index < pathCount; index++ ) {
		workURL = [[NSURL alloc] initFileURLWithPath:[self objectAtIndex:index]];
		if( workURL )
			[urlArray addObject:workURL];
	}
	
	outArray = [NSArray arrayWithArray:urlArray];
	return outArray;
}

-(NSArray*)arrayOfPathsFromURLs
{
	NSInteger		pathCount = [self count];
	NSInteger		index = 0;
	NSMutableArray*	urlArray = [NSMutableArray arrayWithCapacity:pathCount];
	NSString*		workString = nil;
	NSArray*		outArray = nil;
	
	//	Create array of urls from array of paths
	for( index=0; index < pathCount; index++ ) {
		workString = [[NSString alloc] initWithString:[[self objectAtIndex:index] path]];
		if( workString )
			[urlArray addObject:workString];
	}
	
	outArray = [NSArray arrayWithArray:urlArray];
	return outArray;
}

-(NSArray*)arrayOfPathsThatConformToUTIs:(NSArray*)theUTIs resultsAsURL:(BOOL)saveURLs
{
	NSArray*			outArray = nil;
	NSMutableArray*		workArray = [[NSMutableArray alloc] initWithCapacity:0];
	NSEnumerator*		workEnum = [self objectEnumerator];
	NSString*			workPath = nil;
	NSURL*				workURL = nil;
	
	if( workArray != nil )
	{
		while ( workPath = (NSString*)[workEnum nextObject] ) {
			workURL = [NSURL fileURLWithPath:workPath];
			if( workURL != nil )
				if( CFURLConfromsToUTIs( kCFAllocatorDefault, (CFURLRef)workURL, (CFArrayRef)theUTIs, NULL ) )
					[workArray addObject:( saveURLs == YES ) ? workURL : [NSString stringWithString:workPath]];
		}
	
		outArray = [NSArray arrayWithArray:workArray];
		[workArray release];
	}
	
	return outArray;
}

-(id)randomObject
{
	id			outObject = nil;
	float		randFloat = ( random() / (pow(2, 31) - 1) );
	NSInteger	selfCount = [self count];
	NSInteger	randIndex = randFloat * selfCount;
	
	if( randIndex == selfCount )
		randIndex--;
	
	if( selfCount > 0 )
		outObject = [self objectAtIndex:randIndex];
	
	return outObject;
}


@end

@implementation NSMutableArray (MyExtensions)

-(void)insertObjectsFromArray:(NSArray *)array atIndex:(NSInteger)index
{
	id				entry = nil;
	NSEnumerator*	enumerator = [array objectEnumerator];
	
	while ( entry = [enumerator nextObject] ) 
		[self insertObject:entry atIndex:index++];
}

-(id)reverseObjects
{
	NSInteger	arrayIndex, arrayCount = [self count] / 2;
	NSInteger	arrayOut = [self count] -1;
	
	for( arrayIndex=0; arrayIndex < arrayCount; arrayIndex++ )
		[self exchangeObjectAtIndex:arrayIndex withObjectAtIndex:arrayOut-arrayIndex];
	
	return self;
}

-(id)insertUniqueObjectsFromArray:(NSArray*)newArray atIndex:(NSInteger)index
{
	NSEnumerator*	newEnum = [newArray objectEnumerator];
	id				newItem = nil;
	
	while ( newItem = [newEnum nextObject] )
		if( [self indexOfObject:newItem] == NSNotFound )
			[self insertObject:newItem atIndex:index++];
	
	return self;
}

-(id)addUniqueObjectsFromArray:(NSArray*)newArray
	{ return [self insertUniqueObjectsFromArray:newArray atIndex:[self count]]; }

@end
