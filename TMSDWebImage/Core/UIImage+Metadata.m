/*
 * This file is part of the TMSDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import <TMSDWebImage/UIImage+Metadata.h>
#import <TMSDWebImage/NSImage+Compatibility.h>
#import <TMSDWebImage/TMSDInternalMacros.h>
#import "objc/runtime.h"

@implementation UIImage (TMSDMetadata)

#if TMSD_UIKIT || TMSD_WATCH

- (NSUInteger)tmsd_imageLoopCount {
    NSUInteger imageLoopCount = 0;
    NSNumber *value = objc_getAssociatedObject(self, @selector(tmsd_imageLoopCount));
    if ([value isKindOfClass:[NSNumber class]]) {
        imageLoopCount = value.unsignedIntegerValue;
    }
    return imageLoopCount;
}

- (void)setTmsd_imageLoopCount:(NSUInteger)tmsd_imageLoopCount {
    NSNumber *value = @(tmsd_imageLoopCount);
    objc_setAssociatedObject(self, @selector(tmsd_imageLoopCount), value, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSUInteger)tmsd_imageFrameCount {
    NSArray<UIImage *> *animatedImages = self.images;
    if (!animatedImages || animatedImages.count <= 1) {
        return 1;
    }
    NSNumber *value = objc_getAssociatedObject(self, @selector(tmsd_imageFrameCount));
    if ([value isKindOfClass:[NSNumber class]]) {
        return [value unsignedIntegerValue];
    }
    __block NSUInteger frameCount = 1;
    __block UIImage *previousImage = animatedImages.firstObject;
    [animatedImages enumerateObjectsUsingBlock:^(UIImage * _Nonnull image, NSUInteger idx, BOOL * _Nonnull stop) {
        // ignore first
        if (idx == 0) {
            return;
        }
        if (![image isEqual:previousImage]) {
            frameCount++;
        }
        previousImage = image;
    }];
    objc_setAssociatedObject(self, @selector(tmsd_imageFrameCount), @(frameCount), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    return frameCount;
}

- (BOOL)tmsd_isAnimated {
    return (self.images != nil);
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
- (BOOL)tmsd_isVector {
    if (@available(iOS 13.0, tvOS 13.0, watchOS 6.0, *)) {
        // Xcode 11 supports symbol image, keep Xcode 10 compatible currently
        SEL SymbolSelector = NSSelectorFromString(@"isSymbolImage");
        if ([self respondsToSelector:SymbolSelector] && [self performSelector:SymbolSelector]) {
            return YES;
        }
        // SVG
        SEL SVGSelector = TMSD_SEL_SPI(CGSVGDocument);
        if ([self respondsToSelector:SVGSelector] && [self performSelector:SVGSelector]) {
            return YES;
        }
    }
    if (@available(iOS 11.0, tvOS 11.0, watchOS 4.0, *)) {
        // PDF
        SEL PDFSelector = TMSD_SEL_SPI(CGPDFPage);
        if ([self respondsToSelector:PDFSelector] && [self performSelector:PDFSelector]) {
            return YES;
        }
    }
    return NO;
}
#pragma clang diagnostic pop

#else

- (NSUInteger)tmsd_imageLoopCount {
    NSUInteger imageLoopCount = 0;
    NSRect imageRect = NSMakeRect(0, 0, self.size.width, self.size.height);
    NSImageRep *imageRep = [self bestRepresentationForRect:imageRect context:nil hints:nil];
    NSBitmapImageRep *bitmapImageRep;
    if ([imageRep isKindOfClass:[NSBitmapImageRep class]]) {
        bitmapImageRep = (NSBitmapImageRep *)imageRep;
    }
    if (bitmapImageRep) {
        imageLoopCount = [[bitmapImageRep valueForProperty:NSImageLoopCount] unsignedIntegerValue];
    }
    return imageLoopCount;
}

- (void)setTmsd_imageLoopCount:(NSUInteger)tmsd_imageLoopCount {
    NSRect imageRect = NSMakeRect(0, 0, self.size.width, self.size.height);
    NSImageRep *imageRep = [self bestRepresentationForRect:imageRect context:nil hints:nil];
    NSBitmapImageRep *bitmapImageRep;
    if ([imageRep isKindOfClass:[NSBitmapImageRep class]]) {
        bitmapImageRep = (NSBitmapImageRep *)imageRep;
    }
    if (bitmapImageRep) {
        [bitmapImageRep setProperty:NSImageLoopCount withValue:@(tmsd_imageLoopCount)];
    }
}

- (NSUInteger)tmsd_imageFrameCount {
    NSRect imageRect = NSMakeRect(0, 0, self.size.width, self.size.height);
    NSImageRep *imageRep = [self bestRepresentationForRect:imageRect context:nil hints:nil];
    NSBitmapImageRep *bitmapImageRep;
    if ([imageRep isKindOfClass:[NSBitmapImageRep class]]) {
        bitmapImageRep = (NSBitmapImageRep *)imageRep;
    }
    if (bitmapImageRep) {
        return [[bitmapImageRep valueForProperty:NSImageFrameCount] unsignedIntegerValue];
    }
    return 1;
}

- (BOOL)tmsd_isAnimated {
    BOOL isAnimated = NO;
    NSRect imageRect = NSMakeRect(0, 0, self.size.width, self.size.height);
    NSImageRep *imageRep = [self bestRepresentationForRect:imageRect context:nil hints:nil];
    NSBitmapImageRep *bitmapImageRep;
    if ([imageRep isKindOfClass:[NSBitmapImageRep class]]) {
        bitmapImageRep = (NSBitmapImageRep *)imageRep;
    }
    if (bitmapImageRep) {
        NSUInteger frameCount = [[bitmapImageRep valueForProperty:NSImageFrameCount] unsignedIntegerValue];
        isAnimated = frameCount > 1 ? YES : NO;
    }
    return isAnimated;
}

- (BOOL)tmsd_isVector {
    NSRect imageRect = NSMakeRect(0, 0, self.size.width, self.size.height);
    NSImageRep *imageRep = [self bestRepresentationForRect:imageRect context:nil hints:nil];
    if ([imageRep isKindOfClass:[NSPDFImageRep class]]) {
        return YES;
    }
    if ([imageRep isKindOfClass:[NSEPSImageRep class]]) {
        return YES;
    }
    if ([NSStringFromClass(imageRep.class) hasSuffix:@"NSSVGImageRep"]) {
        return YES;
    }
    return NO;
}

#endif

- (TMSDImageFormat)tmsd_imageFormat {
    TMSDImageFormat imageFormat = TMSDImageFormatUndefined;
    NSNumber *value = objc_getAssociatedObject(self, @selector(tmsd_imageFormat));
    if ([value isKindOfClass:[NSNumber class]]) {
        imageFormat = value.integerValue;
        return imageFormat;
    }
    // Check CGImage's UTType, may return nil for non-Image/IO based image
    CFStringRef uttype = CGImageGetUTType(self.CGImage);
    imageFormat = [NSData tmsd_imageFormatFromUTType:uttype];
    return imageFormat;
}

- (void)setTmsd_imageFormat:(TMSDImageFormat)tmsd_imageFormat {
    objc_setAssociatedObject(self, @selector(tmsd_imageFormat), @(tmsd_imageFormat), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)setTmsd_isIncremental:(BOOL)tmsd_isIncremental {
    objc_setAssociatedObject(self, @selector(tmsd_isIncremental), @(tmsd_isIncremental), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)tmsd_isIncremental {
    NSNumber *value = objc_getAssociatedObject(self, @selector(tmsd_isIncremental));
    return value.boolValue;
}

- (void)setTmsd_decodeOptions:(TMSDImageCoderOptions *)tmsd_decodeOptions {
    objc_setAssociatedObject(self, @selector(tmsd_decodeOptions), tmsd_decodeOptions, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (TMSDImageCoderOptions *)tmsd_decodeOptions {
    TMSDImageCoderOptions *value = objc_getAssociatedObject(self, @selector(tmsd_decodeOptions));
    if ([value isKindOfClass:NSDictionary.class]) {
        return value;
    }
    return nil;
}

@end
