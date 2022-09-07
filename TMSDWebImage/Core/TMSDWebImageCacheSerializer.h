/*
 * This file is part of the TMSDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import <Foundation/Foundation.h>
#import <TMSDWebImage/TMSDWebImageCompat.h>

typedef NSData * _Nullable(^TMSDWebImageCacheSerializerBlock)(UIImage * _Nonnull image, NSData * _Nullable data, NSURL * _Nullable imageURL);

/**
 This is the protocol for cache serializer.
 We can use a block to specify the cache serializer. But Using protocol can make this extensible, and allow Swift user to use it easily instead of using `@convention(block)` to store a block into context options.
 */
@protocol TMSDWebImageCacheSerializer <NSObject>

/// Provide the image data associated to the image and store to disk cache
/// @param image The loaded image
/// @param data The original loaded image data
/// @param imageURL The image URL
- (nullable NSData *)cacheDataWithImage:(nonnull UIImage *)image originalData:(nullable NSData *)data imageURL:(nullable NSURL *)imageURL;

@end

/**
 A cache serializer class with block.
 */
@interface TMSDWebImageCacheSerializer : NSObject <TMSDWebImageCacheSerializer>

- (nonnull instancetype)initWithBlock:(nonnull TMSDWebImageCacheSerializerBlock)block;
+ (nonnull instancetype)cacheSerializerWithBlock:(nonnull TMSDWebImageCacheSerializerBlock)block;

@end
