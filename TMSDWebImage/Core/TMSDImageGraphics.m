/*
 * This file is part of the TMSDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import <TMSDWebImage/TMSDImageGraphics.h>
#import <TMSDWebImage/NSImage+Compatibility.h>
#import <TMSDWebImage/TMSDImageCoderHelper.h>
#import "objc/runtime.h"

#if TMSD_MAC
static void *kNSGraphicsContextScaleFactorKey;

static CGContextRef TMSDCGContextCreateBitmapContext(CGSize size, BOOL opaque, CGFloat scale) {
    if (scale == 0) {
        // Match `UIGraphicsBeginImageContextWithOptions`, reset to the scale factor of the device’s main screen if scale is 0.
        NSScreen *mainScreen = nil;
        if (@available(macOS 10.12, *)) {
            mainScreen = [NSScreen mainScreen];
        } else {
            mainScreen = [NSScreen screens].firstObject;
        }
        scale = mainScreen.backingScaleFactor ?: 1.0f;
    }
    size_t width = ceil(size.width * scale);
    size_t height = ceil(size.height * scale);
    if (width < 1 || height < 1) return NULL;
    
    CGColorSpaceRef space = [TMSDImageCoderHelper colorSpaceGetDeviceRGB];
    // kCGImageAlphaNone is not supported in CGBitmapContextCreate.
    // Check #3330 for more detail about why this bitmap is choosen.
    CGBitmapInfo bitmapInfo;
    if (!opaque) {
        // iPhone GPU prefer to use BGRA8888, see: https://forums.raywenderlich.com/t/why-mtlpixelformat-bgra8unorm/53489
        // BGRA8888
        bitmapInfo = kCGBitmapByteOrder32Host | kCGImageAlphaPremultipliedFirst;
    } else {
        // BGR888 previously works on iOS 8~iOS 14, however, iOS 15+ will result a black image. FB9958017
        // RGB888
        bitmapInfo = kCGBitmapByteOrderDefault | kCGImageAlphaNoneSkipLast;
    }
    CGContextRef context = CGBitmapContextCreate(NULL, width, height, 8, 0, space, bitmapInfo);
    if (!context) {
        return NULL;
    }
    CGContextScaleCTM(context, scale, scale);
    
    return context;
}
#endif

CGContextRef TMSDGraphicsGetCurrentContext(void) {
#if TMSD_UIKIT || TMSD_WATCH
    return UIGraphicsGetCurrentContext();
#else
    return NSGraphicsContext.currentContext.CGContext;
#endif
}

void TMSDGraphicsBeginImageContext(CGSize size) {
#if TMSD_UIKIT || TMSD_WATCH
    UIGraphicsBeginImageContext(size);
#else
    TMSDGraphicsBeginImageContextWithOptions(size, NO, 1.0);
#endif
}

void TMSDGraphicsBeginImageContextWithOptions(CGSize size, BOOL opaque, CGFloat scale) {
#if TMSD_UIKIT || TMSD_WATCH
    UIGraphicsBeginImageContextWithOptions(size, opaque, scale);
#else
    CGContextRef context = TMSDCGContextCreateBitmapContext(size, opaque, scale);
    if (!context) {
        return;
    }
    NSGraphicsContext *graphicsContext = [NSGraphicsContext graphicsContextWithCGContext:context flipped:NO];
    objc_setAssociatedObject(graphicsContext, &kNSGraphicsContextScaleFactorKey, @(scale), OBJC_ASSOCIATION_RETAIN);
    CGContextRelease(context);
    [NSGraphicsContext saveGraphicsState];
    NSGraphicsContext.currentContext = graphicsContext;
#endif
}

void TMSDGraphicsEndImageContext(void) {
#if TMSD_UIKIT || TMSD_WATCH
    UIGraphicsEndImageContext();
#else
    [NSGraphicsContext restoreGraphicsState];
#endif
}

UIImage * TMSDGraphicsGetImageFromCurrentImageContext(void) {
#if TMSD_UIKIT || TMSD_WATCH
    return UIGraphicsGetImageFromCurrentImageContext();
#else
    NSGraphicsContext *context = NSGraphicsContext.currentContext;
    CGContextRef contextRef = context.CGContext;
    if (!contextRef) {
        return nil;
    }
    CGImageRef imageRef = CGBitmapContextCreateImage(contextRef);
    if (!imageRef) {
        return nil;
    }
    CGFloat scale = 0;
    NSNumber *scaleFactor = objc_getAssociatedObject(context, &kNSGraphicsContextScaleFactorKey);
    if ([scaleFactor isKindOfClass:[NSNumber class]]) {
        scale = scaleFactor.doubleValue;
    }
    if (!scale) {
        // reset to the scale factor of the device’s main screen if scale is 0.
        NSScreen *mainScreen = nil;
        if (@available(macOS 10.12, *)) {
            mainScreen = [NSScreen mainScreen];
        } else {
            mainScreen = [NSScreen screens].firstObject;
        }
        scale = mainScreen.backingScaleFactor ?: 1.0f;
    }
    NSImage *image = [[NSImage alloc] initWithCGImage:imageRef scale:scale orientation:kCGImagePropertyOrientationUp];
    CGImageRelease(imageRef);
    return image;
#endif
}
