/*
 * This file is part of the TMSDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import <TMSDWebImage/TMSDImageCacheDefine.h>
#import <TMSDWebImage/TMSDImageCodersManager.h>
#import <TMSDWebImage/TMSDImageCoderHelper.h>
#import <TMSDWebImage/TMSDAnimatedImage.h>
#import <TMSDWebImage/UIImage+Metadata.h>
#import <TMSDWebImage/TMSDInternalMacros.h>

TMSDImageCoderOptions * _Nonnull TMSDGetDecodeOptionsFromContext(TMSDWebImageContext * _Nullable context, TMSDWebImageOptions options, NSString * _Nonnull cacheKey) {
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
    
    return coderOptions;
}

UIImage * _Nullable TMSDImageCacheDecodeImageData(NSData * _Nonnull imageData, NSString * _Nonnull cacheKey, TMSDWebImageOptions options, TMSDWebImageContext * _Nullable context) {
    NSCParameterAssert(imageData);
    NSCParameterAssert(cacheKey);
    UIImage *image;
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
        Class animatedImageClass = context[TMSDWebImageContextAnimatedImageClass];
        // check whether we should use `TMSDAnimatedImage`
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
