//
//  NSURLCache+StackableURLCaching.h
//  Stackable URLCaching - Multiple disk caches!
//
//  Created by Frederic Barthelemy on 2012-10-01.
//

#import <Foundation/Foundation.h>

@class FBStackableURLCache;
/**
 * Include this if you want to permit other libraries you're working with to
 *	add their own URL caches, without them clobbering yours.
 *
 * Risks:
 *	- This uses runtime patching to be able to do its job, in addition
 *		to Objective-C Categories.
 *	- If working with code that doesn't know this class is in play, setSharedURLCache:nil becomes ambiguous.
 *		As a result, if this happens, it's recommended that NSURLCache instances implement the optional protocol: FBURLCacheStacking
 */
@interface NSURLCache (StackableURLCaching)

@end
