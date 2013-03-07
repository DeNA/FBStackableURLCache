//
//  FBStackableURLCache.h
//  Stackable URLCaching - Multiple disk caches!
//
//  Created by Frederic Barthelemy on 2012-10-01.
//

#import <Foundation/Foundation.h>

extern NSString * kFBSURLCacheDateSavedKey;

@class FBUnderlyingCache;

@interface FBStackableURLCache : NSURLCache

+ (FBStackableURLCache*)sharedURLCacheStack;
+ (void)setSharedURLCacheStack:(FBStackableURLCache*)cacheStack;

/**
 * Make your block return YES if this request should be dropped, and not processed through the rest of the filter stack.
 * @returns an identifier you can use to deregister the exclusion block at a later time
 */
- (NSString*)registerCacheExclusionBlock:(BOOL (^)(NSURLRequest * request))returnYESToExclude;
- (void)deregisterCacheExclusionBlockByIdentifier:(NSString*)identifier;

/**
 * Make your inclusion block return YES if this request should be processed by this filter.
 * @returns an identifier you can use to deregister the filter at a later time
 */
- (NSString*)registerCacheInclusionFilter:(BOOL (^)(NSURLRequest * request))returnYESToInclude
								   lookup:(NSCachedURLResponse* (^)(NSURLRequest* request))lookup
								  storage:(void (^)(NSCachedURLResponse* response, NSURLRequest * request))storage;
- (void)deregisterCacheInclusionFilterByIdentifier:(NSString*)identifier;

/**
 * If you need to bypass the FBStackableURLCache logic,, access the methods through this proxy object
 */
@property (nonatomic, readonly, strong) FBUnderlyingCache* underlyingCache;


/**
 * If NSURLCache (StackableURLCaching) category is in play, then if someone calls setSharedURLCache with a non FBStackableURLCache subclass, the new cache will be stored here.
 */
@property (nonatomic, readwrite, strong) NSURLCache* childURLCache;

@end

@interface FBUnderlyingCache : NSObject
- (NSCachedURLResponse *)cachedResponseForRequest:(NSURLRequest *)request;
- (void)storeCachedResponse:(NSCachedURLResponse *)cachedResponse forRequest:(NSURLRequest *)request;
@end
