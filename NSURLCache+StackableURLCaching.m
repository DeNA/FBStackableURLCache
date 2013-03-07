//
//  NSURLCache+StackableURLCaching.m
//  Stackable URLCaching - Multiple disk caches!
//
//  Created by Frederic Barthelemy on 2012-10-01.
//

#import <objc/runtime.h>
#import <Foundation/Foundation.h>

#import "NSURLCache+StackableURLCaching.h"
#import "FBStackableURLCache.h"

@implementation NSURLCache (StackableURLCaching)

+ (void)original_setSharedURLCache:(NSURLCache*)childCache
{
	FBStackableURLCache * cacheStack = (FBStackableURLCache*)[FBStackableURLCache sharedURLCache];
	if (cacheStack && ![childCache isKindOfClass:[FBStackableURLCache class]]){
		cacheStack.childURLCache = childCache;
	} else {
		[self original_setSharedURLCache: childCache];
	}
}

+ (void)load {
	// Uses runtime method patching to do it's magic!
    method_exchangeImplementations(class_getInstanceMethod(self, @selector(setSharedURLCache:)), class_getInstanceMethod(self, @selector(original_setSharedURLCache:)));
}

@end
