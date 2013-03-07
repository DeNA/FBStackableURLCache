//
//  FBStackableURLCache.m
//  Stackable URLCaching - Multiple disk caches!
//
//  Created by Frederic Barthelemy on 2012-10-01.
//

#import "FBStackableURLCache.h"

FBStackableURLCache * rootStackableURLCache = nil;
NSString * kFBSURLCacheDateSavedKey = @"FBStackableURLCache_DateSaved";

@interface FBUnderlyingCache ()
- (id)initWithCache:(FBStackableURLCache*)parentCache;
@end

NSString * FBStackableIdentifier();
NSString * FBStackableIdentifier(){
	static NSInteger identifier = 0;
	@synchronized([FBStackableURLCache class]){
		return [NSString stringWithFormat:@"%d",identifier++];
	}
}

#pragma mark - Helper Components
@interface FBStackableURLComponent : NSObject
@property (nonatomic, readwrite, strong) NSString* identifier;
@end
@implementation FBStackableURLComponent
@synthesize identifier;
- (id)init
{
	if ((self = [super init])){
		self.identifier = FBStackableIdentifier();
	}
	return self;
}
@end
@interface FBStackableURLExclusion : FBStackableURLComponent
@property (nonatomic, readwrite, copy) BOOL (^exclude)(NSURLRequest * request);
@end
@implementation FBStackableURLExclusion
@synthesize exclude;
- (NSString *)description
{
	return [NSString stringWithFormat:@"<FBStackableURLExclusion:%p identifier:%@ exclude:%@>",self, self.identifier, self.exclude];
}
@end
@interface FBStackableURLFilter : FBStackableURLComponent
@property (nonatomic, readwrite, copy) BOOL (^include)(NSURLRequest * request);
@property (nonatomic, readwrite, copy) NSCachedURLResponse* (^lookup)(NSURLRequest* request);
@property (nonatomic, readwrite, copy) void (^store)(NSCachedURLResponse* response, NSURLRequest * request);
@end
@implementation FBStackableURLFilter
@synthesize include, lookup, store;
- (NSString *)description
{
	return [NSString stringWithFormat:@"<FBStackableURLExclusion:%p identifier:%@ include:%@ lookup:%@ store:%@>",self, self.identifier, self.include, self.lookup, self.store];
}
@end

#pragma mark -
@implementation FBStackableURLCache
{
	NSMutableArray * exclusions;
	NSMutableArray * filters;
	FBUnderlyingCache *underlyingCache;
}
- (FBUnderlyingCache*)underlyingCache
{
	if (!underlyingCache){
		underlyingCache = [[FBUnderlyingCache alloc] initWithCache:self];
	}
	return underlyingCache;
}

+ (NSURLCache*)sharedURLCache
{
	return [[self sharedURLCacheStack] childURLCache] ?: [super sharedURLCache];
}

+ (FBStackableURLCache *)sharedURLCacheStack
{
	@synchronized(self){
		return rootStackableURLCache;
	}
}

+ (void)setSharedURLCacheStack:(FBStackableURLCache *)cacheStack
{
	@synchronized(self){
		rootStackableURLCache = cacheStack;
		[super setSharedURLCache:rootStackableURLCache];
	}
}

- (NSString*)registerCacheExclusionBlock:(BOOL (^)(NSURLRequest *))returnYESToExclude
{
	FBStackableURLExclusion * exclusion = [[FBStackableURLExclusion alloc] init];
	exclusion.exclude = returnYESToExclude;
	[exclusions addObject:exclusion];
	return exclusion.identifier;
}
- (void)deregisterCacheExclusionBlockByIdentifier:(NSString *)identifier
{
	[exclusions enumerateObjectsUsingBlock:^(FBStackableURLComponent* obj, NSUInteger idx, BOOL *stop) {
		if ([obj.identifier isEqualToString:identifier]) {
			*stop = YES;
			[exclusions removeObjectAtIndex:idx];
		}
	}];
}
- (NSString*)registerCacheInclusionFilter:(BOOL (^)(NSURLRequest *))returnYESToInclude lookup:(NSCachedURLResponse *(^)(NSURLRequest *))lookup storage:(void (^)(NSCachedURLResponse *, NSURLRequest *))storage
{
	FBStackableURLFilter * filter = [[FBStackableURLFilter alloc] init];
	filter.include = returnYESToInclude;
	filter.lookup = lookup;
	filter.store = storage;
	[filters addObject:filter];
	return filter.identifier;
}
- (void)deregisterCacheInclusionFilterByIdentifier:(NSString *)identifier
{
	[filters enumerateObjectsUsingBlock:^(FBStackableURLComponent* obj, NSUInteger idx, BOOL *stop) {
		if ([obj.identifier isEqualToString:identifier]) {
			*stop = YES;
			[filters removeObjectAtIndex:idx];
		}
	}];
}
#pragma mark - NSURLCache
- (id)initWithMemoryCapacity:(NSUInteger)memoryCapacity diskCapacity:(NSUInteger)diskCapacity diskPath:(NSString *)path
{
	if ((self = [super initWithMemoryCapacity:memoryCapacity diskCapacity:diskCapacity diskPath:path])){
		exclusions = [NSMutableArray array];
		filters = [NSMutableArray array];
	}
	return self;
}

- (FBStackableURLFilter*)_filterForRequest:(NSURLRequest *)request
{
	__block BOOL totalStop = NO;
	[exclusions enumerateObjectsUsingBlock:^(FBStackableURLExclusion* obj, NSUInteger idx, BOOL *stop) {
		if (obj.exclude(request)) {
			*stop = YES;
			totalStop = YES;
		}
	}];
	if (totalStop){return nil;}
	
	__block FBStackableURLFilter * filter = nil;
	[filters enumerateObjectsUsingBlock:^(FBStackableURLFilter* obj, NSUInteger idx, BOOL *stop) {
		if (obj.include(request)) {
			*stop = YES;
			filter = obj;
		}
	}];
	return filter;
}

- (NSCachedURLResponse *)cachedResponseForRequest:(NSURLRequest *)request
{
	FBStackableURLFilter * filter = [self _filterForRequest:request];
	if (filter){
		return filter.lookup(request);
	}
	
	return [self.childURLCache cachedResponseForRequest:request] ?: [super cachedResponseForRequest:request];
}
- (void)storeCachedResponse:(NSCachedURLResponse *)cachedResponse forRequest:(NSURLRequest *)request
{
	FBStackableURLFilter * filter = [self _filterForRequest:request];
	if (filter){
		cachedResponse = [[NSCachedURLResponse alloc] initWithResponse: cachedResponse.response
																  data: cachedResponse.data
															  userInfo: @{ kFBSURLCacheDateSavedKey : [NSDate date] }
														 storagePolicy: NSURLCacheStorageAllowed];
		filter.store(cachedResponse,request);
		return;
	}
	[super storeCachedResponse:cachedResponse forRequest:request];
}
- (void)removeCachedResponseForRequest:(NSURLRequest *)request
{
	FBStackableURLFilter * filter = [self _filterForRequest:request];
	if (filter){
		filter.store(nil,request);
		return;
	}
	
	[self.childURLCache removeCachedResponseForRequest:request];
	[super removeCachedResponseForRequest:request];
}
- (void)removeAllCachedResponses
{
	// Note: this can't remove the linked caches!
	
	[[self childURLCache] removeAllCachedResponses];
	[super removeAllCachedResponses];
}
- (void)super_storeCachedResponse:(NSCachedURLResponse *)cachedResponse forRequest:(NSURLRequest *)request
{
	[super storeCachedResponse:cachedResponse forRequest:request];
}
- (NSCachedURLResponse*)super_cachedResponseForRequest:(NSURLRequest *)request
{
	return [super cachedResponseForRequest:request];
}
@end
@implementation FBUnderlyingCache
{
	__weak FBStackableURLCache *parentCache;
}
- (id)initWithCache:(FBStackableURLCache*)trueCache
{
	if ((self = [super init])){
		parentCache = trueCache;
	}
	return self;
}
- (void)storeCachedResponse:(NSCachedURLResponse *)cachedResponse forRequest:(NSURLRequest *)request
{
	FBStackableURLCache * tmp = parentCache;
	[tmp super_storeCachedResponse:cachedResponse forRequest:request];
}
- (NSCachedURLResponse*)cachedResponseForRequest:(NSURLRequest *)request
{
	FBStackableURLCache * tmp = parentCache;
	return [tmp super_cachedResponseForRequest:request];
}
@end
