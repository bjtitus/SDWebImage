/*
 * This file is part of the TMSDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 * (c) Matt Galloway
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import <TMSDWebImage/TMSDMemoryCache.h>
#import <TMSDWebImage/TMSDDiskCache.h>
#import <TMSDWebImage/TMSDImageCacheDefine.h>

// A really naive implementation of custom memory cache and disk cache
@interface TMSDWebImageTestMemoryCache : NSObject <TMSDMemoryCache>

@property (nonatomic, strong, nonnull) TMSDImageCacheConfig *config;
@property (nonatomic, strong, nonnull) NSCache *cache;

@end

@interface TMSDWebImageTestDiskCache : NSObject <TMSDDiskCache>

@property (nonatomic, strong, nonnull) TMSDImageCacheConfig *config;
@property (nonatomic, copy, nonnull) NSString *cachePath;
@property (nonatomic, strong, nonnull) NSFileManager *fileManager;

@end

// A really naive implementation of custom image cache using memory cache and disk cache
@interface TMSDWebImageTestCache : NSObject <TMSDImageCache>

@property (nonatomic, strong, nonnull) TMSDImageCacheConfig *config;
@property (nonatomic, strong, nonnull) TMSDWebImageTestMemoryCache *memoryCache;
@property (nonatomic, strong, nonnull) TMSDWebImageTestDiskCache *diskCache;

- (nullable instancetype)initWithCachePath:(nonnull NSString *)cachePath config:(nonnull TMSDImageCacheConfig *)config;

@property (nonatomic, class, readonly, nonnull) TMSDWebImageTestCache *sharedCache;

@end
