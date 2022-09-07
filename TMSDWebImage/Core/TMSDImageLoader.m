/*
 * This file is part of the TMSDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import <TMSDWebImage/TMSDImageLoader.h>
#import <TMSDWebImage/TMSDWebImageCacheKeyFilter.h>
#import <TMSDWebImage/TMSDImageCodersManager.h>
#import <TMSDWebImage/TMSDImageCoderHelper.h>
#import <TMSDWebImage/TMSDAnimatedImage.h>
#import <TMSDWebImage/UIImage+Metadata.h>
#import <TMSDWebImage/TMSDInternalMacros.h>
#import <TMSDWebImage/TMSDImageCacheDefine.h>
#import "objc/runtime.h"

TMSDWebImageContextOption const TMSDWebImageContextLoaderCachedImage = @"loaderCachedImage";

static void * TMSDImageLoaderProgressiveCoderKey = &TMSDImageLoaderProgressiveCoderKey;

id<TMSDProgressiveImageCoder> TMSDImageLoaderGetProgressiveCoder(id<TMSDWebImageOperation> operation) {
    NSCParameterAssert(operation);
    return objc_getAssociatedObject(operation, TMSDImageLoaderProgressiveCoderKey);
}

void TMSDImageLoaderSetProgressiveCoder(id<TMSDWebImageOperation> operation, id<TMSDProgressiveImageCoder> progressiveCoder) {
    NSCParameterAssert(operation);
    objc_setAssociatedObject(operation, TMSDImageLoaderProgressiveCoderKey, progressiveCoder, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

UIImage * _Nullable TMSDImageLoaderDecodeImageData(NSData * _Nonnull imageData, NSURL * _Nonnull imageURL, TMSDWebImageOptions options, TMSDWebImageContext * _Nullable context) {
    NSCParameterAssert(imageData);
    NSCParameterAssert(imageURL);
    
    UIImage *image;
    id<TMSDWebImageCacheKeyFilter> cacheKeyFilter = context[TMSDWebImageContextCacheKeyFilter];
    NSString *cacheKey;
    if (cacheKeyFilter) {
        cacheKey = [cacheKeyFilter cacheKeyForURL:imageURL];
    } else {
        cacheKey = imageURL.absoluteString;
    }
    TMSDImageCoderOptions *coderOptions = TMSDGetDecodeOptionsFromContext(context, options, cacheKey);
    BOOL decodeFirstFrame = TMSD_OPTIONS_CONTAINS(options, TMSDWebImageDecodeFirstFrameOnly);
    CGFloat scale = [coderOptions[TMSDImageCoderDecodeScaleFactor] doubleValue];
    
    // Grab the image coder
    id<TMSDImageCoder> imageCoder;
    if ([context[TMSDWebImageContextImageCoder] conformsToProtocol:@protocol(TMSDImageCoder)]) {
        imageCoder = context[TMSDWebImageContextImageCoder];
    } else {
        imageCoder = [TMSDImageCodersManager sharedManager];
    }
    
    if (!decodeFirstFrame) {
        // check whether we should use `TMSDAnimatedImage`
        Class animatedImageClass = context[TMSDWebImageContextAnimatedImageClass];
        if ([animatedImageClass isSubclassOfClass:[UIImage class]] && [animatedImageClass conformsToProtocol:@protocol(TMSDAnimatedImage)]) {
            image = [[animatedImageClass alloc] initWithData:imageData scale:scale options:coderOptions];
            if (image) {
                // Preload frames if supported
                if (options & TMSDWebImagePreloadAllFrames && [image respondsToSelector:@selector(preloadAllFrames)]) {
                    [((id<TMSDAnimatedImage>)image) preloadAllFrames];
                }
            } else {
                // Check image class matching
                if (options & TMSDWebImageMatchAnimatedImageClass) {
                    return nil;
                }
            }
        }
    }
    if (!image) {
        image = [imageCoder decodedImageWithData:imageData options:coderOptions];
    }
    if (image) {
        BOOL shouldDecode = !TMSD_OPTIONS_CONTAINS(options, TMSDWebImageAvoidDecodeImage);
        if ([image.class conformsToProtocol:@protocol(TMSDAnimatedImage)]) {
            // `TMSDAnimatedImage` do not decode
            shouldDecode = NO;
        } else if (image.tmsd_isAnimated) {
            // animated image do not decode
            shouldDecode = NO;
        }
        
        if (shouldDecode) {
            image = [TMSDImageCoderHelper decodedImageWithImage:image];
        }
        // assign the decode options, to let manager check whether to re-decode if needed
        image.tmsd_decodeOptions = coderOptions;
    }
    
    return image;
}

UIImage * _Nullable TMSDImageLoaderDecodeProgressiveImageData(NSData * _Nonnull imageData, NSURL * _Nonnull imageURL, BOOL finished,  id<TMSDWebImageOperation> _Nonnull operation, TMSDWebImageOptions options, TMSDWebImageContext * _Nullable context) {
    NSCParameterAssert(imageData);
    NSCParameterAssert(imageURL);
    NSCParameterAssert(operation);
    
    UIImage *image;
    id<TMSDWebImageCacheKeyFilter> cacheKeyFilter = context[TMSDWebImageContextCacheKeyFilter];
    NSString *cacheKey;
    if (cacheKeyFilter) {
        cacheKey = [cacheKeyFilter cacheKeyForURL:imageURL];
    } else {
        cacheKey = imageURL.absoluteString;
    }
    BOOL decodeFirstFrame = TMSD_OPTIONS_CONTAINS(options, TMSDWebImageDecodeFirstFrameOnly);
    NSNumber *scaleValue = context[TMSDWebImageContextImageScaleFactor];
    CGFloat scale = scaleValue.doubleValue >= 1 ? scaleValue.doubleValue : TMSDImageScaleFactorForKey(cacheKey);
    NSNumber *preserveAspectRatioValue = context[TMSDWebImageContextImagePreserveAspectRatio];
    NSValue *thumbnailSizeValue;
    BOOL shouldScaleDown = TMSD_OPTIONS_CONTAINS(options, TMSDWebImageScaleDownLargeImages);
    if (shouldScaleDown) {
        CGFloat thumbnailPixels = TMSDImageCoderHelper.defaultScaleDownLimitBytes / 4;
        CGFloat dimension = ceil(sqrt(thumbnailPixels));
        thumbnailSizeValue = @(CGSizeMake(dimension, dimension));
    }
    if (context[TMSDWebImageContextImageThumbnailPixelSize]) {
        thumbnailSizeValue = context[TMSDWebImageContextImageThumbnailPixelSize];
    }
    
    TMSDImageCoderMutableOptions *mutableCoderOptions = [NSMutableDictionary dictionaryWithCapacity:2];
    mutableCoderOptions[TMSDImageCoderDecodeFirstFrameOnly] = @(decodeFirstFrame);
    mutableCoderOptions[TMSDImageCoderDecodeScaleFactor] = @(scale);
    mutableCoderOptions[TMSDImageCoderDecodePreserveAspectRatio] = preserveAspectRatioValue;
    mutableCoderOptions[TMSDImageCoderDecodeThumbnailPixelSize] = thumbnailSizeValue;
    mutableCoderOptions[TMSDImageCoderWebImageContext] = context;
    TMSDImageCoderOptions *coderOptions = [mutableCoderOptions copy];
    
    // Grab the progressive image coder
    id<TMSDProgressiveImageCoder> progressiveCoder = TMSDImageLoaderGetProgressiveCoder(operation);
    if (!progressiveCoder) {
        id<TMSDProgressiveImageCoder> imageCoder = context[TMSDWebImageContextImageCoder];
        // Check the progressive coder if provided
        if ([imageCoder conformsToProtocol:@protocol(TMSDProgressiveImageCoder)]) {
            progressiveCoder = [[[imageCoder class] alloc] initIncrementalWithOptions:coderOptions];
        } else {
            // We need to create a new instance for progressive decoding to avoid conflicts
            for (id<TMSDImageCoder> coder in [TMSDImageCodersManager sharedManager].coders.reverseObjectEnumerator) {
                if ([coder conformsToProtocol:@protocol(TMSDProgressiveImageCoder)] &&
                    [((id<TMSDProgressiveImageCoder>)coder) canIncrementalDecodeFromData:imageData]) {
                    progressiveCoder = [[[coder class] alloc] initIncrementalWithOptions:coderOptions];
                    break;
                }
            }
        }
        TMSDImageLoaderSetProgressiveCoder(operation, progressiveCoder);
    }
    // If we can't find any progressive coder, disable progressive download
    if (!progressiveCoder) {
        return nil;
    }
    
    [progressiveCoder updateIncrementalData:imageData finished:finished];
    if (!decodeFirstFrame) {
        // check whether we should use `TMSDAnimatedImage`
        Class animatedImageClass = context[TMSDWebImageContextAnimatedImageClass];
        if ([animatedImageClass isSubclassOfClass:[UIImage class]] && [animatedImageClass conformsToProtocol:@protocol(TMSDAnimatedImage)] && [progressiveCoder conformsToProtocol:@protocol(TMSDAnimatedImageCoder)]) {
            image = [[animatedImageClass alloc] initWithAnimatedCoder:(id<TMSDAnimatedImageCoder>)progressiveCoder scale:scale];
            if (image) {
                // Progressive decoding does not preload frames
            } else {
                // Check image class matching
                if (options & TMSDWebImageMatchAnimatedImageClass) {
                    return nil;
                }
            }
        }
    }
    if (!image) {
        image = [progressiveCoder incrementalDecodedImageWithOptions:coderOptions];
    }
    if (image) {
        BOOL shouldDecode = !TMSD_OPTIONS_CONTAINS(options, TMSDWebImageAvoidDecodeImage);
        if ([image.class conformsToProtocol:@protocol(TMSDAnimatedImage)]) {
            // `TMSDAnimatedImage` do not decode
            shouldDecode = NO;
        } else if (image.tmsd_isAnimated) {
            // animated image do not decode
            shouldDecode = NO;
        }
        if (shouldDecode) {
            image = [TMSDImageCoderHelper decodedImageWithImage:image];
        }
        // mark the image as progressive (completed one are not mark as progressive)
        image.tmsd_isIncremental = !finished;
        // assign the decode options, to let manager check whether to re-decode if needed
        image.tmsd_decodeOptions = coderOptions;
    }
    
    return image;
}
