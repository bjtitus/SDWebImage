/*
 * This file is part of the TMSDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import <Foundation/Foundation.h>
#import <TMSDWebImage/TMSDWebImageCompat.h>
#import <TMSDWebImage/TMSDWebImageDefine.h>

@class TMSDWebImageOptionsResult;

typedef TMSDWebImageOptionsResult * _Nullable(^TMSDWebImageOptionsProcessorBlock)(NSURL * _Nullable url, TMSDWebImageOptions options, TMSDWebImageContext * _Nullable context);

/**
 The options result contains both options and context.
 */
@interface TMSDWebImageOptionsResult : NSObject

/**
 WebCache options.
 */
@property (nonatomic, assign, readonly) TMSDWebImageOptions options;

/**
 Context options.
 */
@property (nonatomic, copy, readonly, nullable) TMSDWebImageContext *context;

/**
 Create a new options result.

 @param options options
 @param context context
 @return The options result contains both options and context.
 */
- (nonnull instancetype)initWithOptions:(TMSDWebImageOptions)options context:(nullable TMSDWebImageContext *)context;

@end

/**
 This is the protocol for options processor.
 Options processor can be used, to control the final result for individual image request's `TMSDWebImageOptions` and `TMSDWebImageContext`
 Implements the protocol to have a global control for each indivadual image request's option.
 */
@protocol TMSDWebImageOptionsProcessor <NSObject>

/**
 Return the processed options result for specify image URL, with its options and context

 @param url The URL to the image
 @param options A mask to specify options to use for this request
 @param context A context contains different options to perform specify changes or processes, see `TMSDWebImageContextOption`. This hold the extra objects which `options` enum can not hold.
 @return The processed result, contains both options and context
 */
- (nullable TMSDWebImageOptionsResult *)processedResultForURL:(nullable NSURL *)url
                                                    options:(TMSDWebImageOptions)options
                                                    context:(nullable TMSDWebImageContext *)context;

@end

/**
 A options processor class with block.
 */
@interface TMSDWebImageOptionsProcessor : NSObject<TMSDWebImageOptionsProcessor>

- (nonnull instancetype)initWithBlock:(nonnull TMSDWebImageOptionsProcessorBlock)block;
+ (nonnull instancetype)optionsProcessorWithBlock:(nonnull TMSDWebImageOptionsProcessorBlock)block;

@end
