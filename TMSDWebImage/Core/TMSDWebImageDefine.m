/*
 * This file is part of the TMSDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import <TMSDWebImage/TMSDWebImageDefine.h>
#import <TMSDWebImage/UIImage+Metadata.h>
#import <TMSDWebImage/NSImage+Compatibility.h>
#import <TMSDWebImage/TMSDAssociatedObject.h>

#pragma mark - Image scale

static inline NSArray<NSNumber *> * _Nonnull TMSDImageScaleFactors() {
    return @[@2, @3];
}

inline CGFloat TMSDImageScaleFactorForKey(NSString * _Nullable key) {
    CGFloat scale = 1;
    if (!key) {
        return scale;
    }
    // Check if target OS support scale
#if TMSD_WATCH
    if ([[WKInterfaceDevice currentDevice] respondsToSelector:@selector(screenScale)])
#elif TMSD_UIKIT
    if ([[UIScreen mainScreen] respondsToSelector:@selector(scale)])
#elif TMSD_MAC
    NSScreen *mainScreen = nil;
    if (@available(macOS 10.12, *)) {
        mainScreen = [NSScreen mainScreen];
    } else {
        mainScreen = [NSScreen screens].firstObject;
    }
    if ([mainScreen respondsToSelector:@selector(backingScaleFactor)])
#endif
    {
        // a@2x.png -> 8
        if (key.length >= 8) {
            // Fast check
            BOOL isURL = [key hasPrefix:@"http://"] || [key hasPrefix:@"https://"];
            for (NSNumber *scaleFactor in TMSDImageScaleFactors()) {
                // @2x. for file name and normal url
                NSString *fileScale = [NSString stringWithFormat:@"@%@x.", scaleFactor];
                if ([key containsString:fileScale]) {
                    scale = scaleFactor.doubleValue;
                    return scale;
                }
                if (isURL) {
                    // %402x. for url encode
                    NSString *urlScale = [NSString stringWithFormat:@"%%40%@x.", scaleFactor];
                    if ([key containsString:urlScale]) {
                        scale = scaleFactor.doubleValue;
                        return scale;
                    }
                }
            }
        }
    }
    return scale;
}

inline UIImage * _Nullable TMSDScaledImageForKey(NSString * _Nullable key, UIImage * _Nullable image) {
    if (!image) {
        return nil;
    }
    CGFloat scale = TMSDImageScaleFactorForKey(key);
    return TMSDScaledImageForScaleFactor(scale, image);
}

inline UIImage * _Nullable TMSDScaledImageForScaleFactor(CGFloat scale, UIImage * _Nullable image) {
    if (!image) {
        return nil;
    }
    if (scale <= 1) {
        return image;
    }
    if (scale == image.scale) {
        return image;
    }
    UIImage *scaledImage;
    if (image.tmsd_isAnimated) {
        UIImage *animatedImage;
#if TMSD_UIKIT || TMSD_WATCH
        // `UIAnimatedImage` images share the same size and scale.
        NSMutableArray<UIImage *> *scaledImages = [NSMutableArray array];
        
        for (UIImage *tempImage in image.images) {
            UIImage *tempScaledImage = [[UIImage alloc] initWithCGImage:tempImage.CGImage scale:scale orientation:tempImage.imageOrientation];
            [scaledImages addObject:tempScaledImage];
        }
        
        animatedImage = [UIImage animatedImageWithImages:scaledImages duration:image.duration];
        animatedImage.tmsd_imageLoopCount = image.tmsd_imageLoopCount;
#else
        // Animated GIF for `NSImage` need to grab `NSBitmapImageRep`;
        NSRect imageRect = NSMakeRect(0, 0, image.size.width, image.size.height);
        NSImageRep *imageRep = [image bestRepresentationForRect:imageRect context:nil hints:nil];
        NSBitmapImageRep *bitmapImageRep;
        if ([imageRep isKindOfClass:[NSBitmapImageRep class]]) {
            bitmapImageRep = (NSBitmapImageRep *)imageRep;
        }
        if (bitmapImageRep) {
            NSSize size = NSMakeSize(image.size.width / scale, image.size.height / scale);
            animatedImage = [[NSImage alloc] initWithSize:size];
            bitmapImageRep.size = size;
            [animatedImage addRepresentation:bitmapImageRep];
        }
#endif
        scaledImage = animatedImage;
    } else {
#if TMSD_UIKIT || TMSD_WATCH
        scaledImage = [[UIImage alloc] initWithCGImage:image.CGImage scale:scale orientation:image.imageOrientation];
#else
        scaledImage = [[UIImage alloc] initWithCGImage:image.CGImage scale:scale orientation:kCGImagePropertyOrientationUp];
#endif
    }
    TMSDImageCopyAssociatedObject(image, scaledImage);
    
    return scaledImage;
}

#pragma mark - Context option

TMSDWebImageContextOption const TMSDWebImageContextSetImageOperationKey = @"setImageOperationKey";
TMSDWebImageContextOption const TMSDWebImageContextCustomManager = @"customManager";
TMSDWebImageContextOption const TMSDWebImageContextImageCache = @"imageCache";
TMSDWebImageContextOption const TMSDWebImageContextImageLoader = @"imageLoader";
TMSDWebImageContextOption const TMSDWebImageContextImageCoder = @"imageCoder";
TMSDWebImageContextOption const TMSDWebImageContextImageTransformer = @"imageTransformer";
TMSDWebImageContextOption const TMSDWebImageContextImageScaleFactor = @"imageScaleFactor";
TMSDWebImageContextOption const TMSDWebImageContextImagePreserveAspectRatio = @"imagePreserveAspectRatio";
TMSDWebImageContextOption const TMSDWebImageContextImageThumbnailPixelSize = @"imageThumbnailPixelSize";
TMSDWebImageContextOption const TMSDWebImageContextQueryCacheType = @"queryCacheType";
TMSDWebImageContextOption const TMSDWebImageContextStoreCacheType = @"storeCacheType";
TMSDWebImageContextOption const TMSDWebImageContextOriginalQueryCacheType = @"originalQueryCacheType";
TMSDWebImageContextOption const TMSDWebImageContextOriginalStoreCacheType = @"originalStoreCacheType";
TMSDWebImageContextOption const TMSDWebImageContextOriginalImageCache = @"originalImageCache";
TMSDWebImageContextOption const TMSDWebImageContextAnimatedImageClass = @"animatedImageClass";
TMSDWebImageContextOption const TMSDWebImageContextDownloadRequestModifier = @"downloadRequestModifier";
TMSDWebImageContextOption const TMSDWebImageContextDownloadResponseModifier = @"downloadResponseModifier";
TMSDWebImageContextOption const TMSDWebImageContextDownloadDecryptor = @"downloadDecryptor";
TMSDWebImageContextOption const TMSDWebImageContextCacheKeyFilter = @"cacheKeyFilter";
TMSDWebImageContextOption const TMSDWebImageContextCacheSerializer = @"cacheSerializer";
