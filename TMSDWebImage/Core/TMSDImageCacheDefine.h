/*
 * This file is part of the TMSDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import <Foundation/Foundation.h>
#import <TMSDWebImage/TMSDWebImageCompat.h>
#import <TMSDWebImage/TMSDWebImageOperation.h>
#import <TMSDWebImage/TMSDWebImageDefine.h>
#import <TMSDWebImage/TMSDImageCoder.h>

/// Image Cache Type
typedef NS_ENUM(NSInteger, TMSDImageCacheType) {
    /**
     * For query and contains op in response, means the image isn't available in the image cache
     * For op in request, this type is not available and take no effect.
     */
    TMSDImageCacheTypeNone,
    /**
     * For query and contains op in response, means the image was obtained from the disk cache.
     * For op in request, means process only disk cache.
     */
    TMSDImageCacheTypeDisk,
    /**
     * For query and contains op in response, means the image was obtained from the memory cache.
     * For op in request, means process only memory cache.
     */
    TMSDImageCacheTypeMemory,
    /**
     * For query and contains op in response, this type is not available and take no effect.
     * For op in request, means process both memory cache and disk cache.
     */
    TMSDImageCacheTypeAll
};

typedef void(^TMSDImageCacheCheckCompletionBlock)(BOOL isInCache);
typedef void(^TMSDImageCacheQueryDataCompletionBlock)(NSData * _Nullable data);
typedef void(^TMSDImageCacheCalculateSizeBlock)(NSUInteger fileCount, NSUInteger totalSize);
typedef NSString * _Nullable (^TMSDImageCacheAdditionalCachePathBlock)(NSString * _Nonnull key);
typedef void(^TMSDImageCacheQueryCompletionBlock)(UIImage * _Nullable image, NSData * _Nullable data, TMSDImageCacheType cacheType);
typedef void(^TMSDImageCacheContainsCompletionBlock)(TMSDImageCacheType containsCacheType);

/**
 This is the built-in decoding process for image query from cache.
 @note If you want to implement your custom loader with `queryImageForKey:options:context:completion:` API, but also want to keep compatible with TMSDWebImage's behavior, you'd better use this to produce image.
 
 @param imageData The image data from the cache. Should not be nil
 @param cacheKey The image cache key from the input. Should not be nil
 @param options The options arg from the input
 @param context The context arg from the input
 @return The decoded image for current image data query from cache
 */
FOUNDATION_EXPORT UIImage * _Nullable TMSDImageCacheDecodeImageData(NSData * _Nonnull imageData, NSString * _Nonnull cacheKey, TMSDWebImageOptions options, TMSDWebImageContext * _Nullable context);

/// Get the decode options from the loading context options and cache key. This is the built-in translate between the web loading part to the decoding part (which does not depens on).
/// @param context The options arg from the input
/// @param options The context arg from the input
/// @param cacheKey The image cache key from the input. Should not be nil
FOUNDATION_EXPORT TMSDImageCoderOptions * _Nonnull TMSDGetDecodeOptionsFromContext(TMSDWebImageContext * _Nullable context, TMSDWebImageOptions options, NSString * _Nonnull cacheKey);

/**
 This is the image cache protocol to provide custom image cache for `TMSDWebImageManager`.
 Though the best practice to custom image cache, is to write your own class which conform `TMSDMemoryCache` or `TMSDDiskCache` protocol for `TMSDImageCache` class (See more on `TMSDImageCacheConfig.memoryCacheClass & TMSDImageCacheConfig.diskCacheClass`).
 However, if your own cache implementation contains more advanced feature beyond `TMSDImageCache` itself, you can consider to provide this instead. For example, you can even use a cache manager like `TMSDImageCachesManager` to register multiple caches.
 */
@protocol TMSDImageCache <NSObject>

@required
/**
 Query the cached image from image cache for given key. The operation can be used to cancel the query.
 If image is cached in memory, completion is called synchronously, else asynchronously and depends on the options arg (See `TMSDWebImageQueryDiskSync`)

 @param key The image cache key
 @param options A mask to specify options to use for this query
 @param context A context contains different options to perform specify changes or processes, see `TMSDWebImageContextOption`. This hold the extra objects which `options` enum can not hold.
 @param completionBlock The completion block. Will not get called if the operation is cancelled
 @return The operation for this query
 */
- (nullable id<TMSDWebImageOperation>)queryImageForKey:(nullable NSString *)key
                                             options:(TMSDWebImageOptions)options
                                             context:(nullable TMSDWebImageContext *)context
                                          completion:(nullable TMSDImageCacheQueryCompletionBlock)completionBlock;

/**
 Query the cached image from image cache for given key. The operation can be used to cancel the query.
 If image is cached in memory, completion is called synchronously, else asynchronously and depends on the options arg (See `TMSDWebImageQueryDiskSync`)

 @param key The image cache key
 @param options A mask to specify options to use for this query
 @param context A context contains different options to perform specify changes or processes, see `TMSDWebImageContextOption`. This hold the extra objects which `options` enum can not hold.
 @param cacheType Specify where to query the cache from. By default we use `.all`, which means both memory cache and disk cache. You can choose to query memory only or disk only as well. Pass `.none` is invalid and callback with nil immediately.
 @param completionBlock The completion block. Will not get called if the operation is cancelled
 @return The operation for this query
 */
- (nullable id<TMSDWebImageOperation>)queryImageForKey:(nullable NSString *)key
                                             options:(TMSDWebImageOptions)options
                                             context:(nullable TMSDWebImageContext *)context
                                           cacheType:(TMSDImageCacheType)cacheType
                                          completion:(nullable TMSDImageCacheQueryCompletionBlock)completionBlock;

/**
 Store the image into image cache for the given key. If cache type is memory only, completion is called synchronously, else asynchronously.

 @param image The image to store
 @param imageData The image data to be used for disk storage
 @param key The image cache key
 @param cacheType The image store op cache type
 @param completionBlock A block executed after the operation is finished
 */
- (void)storeImage:(nullable UIImage *)image
         imageData:(nullable NSData *)imageData
            forKey:(nullable NSString *)key
         cacheType:(TMSDImageCacheType)cacheType
        completion:(nullable TMSDWebImageNoParamsBlock)completionBlock;

/**
 Remove the image from image cache for the given key. If cache type is memory only, completion is called synchronously, else asynchronously.

 @param key The image cache key
 @param cacheType The image remove op cache type
 @param completionBlock A block executed after the operation is finished
 */
- (void)removeImageForKey:(nullable NSString *)key
                cacheType:(TMSDImageCacheType)cacheType
               completion:(nullable TMSDWebImageNoParamsBlock)completionBlock;

/**
 Check if image cache contains the image for the given key (does not load the image). If image is cached in memory, completion is called synchronously, else asynchronously.

 @param key The image cache key
 @param cacheType The image contains op cache type
 @param completionBlock A block executed after the operation is finished.
 */
- (void)containsImageForKey:(nullable NSString *)key
                  cacheType:(TMSDImageCacheType)cacheType
                 completion:(nullable TMSDImageCacheContainsCompletionBlock)completionBlock;

/**
 Clear all the cached images for image cache. If cache type is memory only, completion is called synchronously, else asynchronously.

 @param cacheType The image clear op cache type
 @param completionBlock A block executed after the operation is finished
 */
- (void)clearWithCacheType:(TMSDImageCacheType)cacheType
                completion:(nullable TMSDWebImageNoParamsBlock)completionBlock;

@end
