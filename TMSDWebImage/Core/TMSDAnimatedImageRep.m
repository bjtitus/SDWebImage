/*
 * This file is part of the TMSDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import <TMSDWebImage/TMSDAnimatedImageRep.h>

#if TMSD_MAC

#import <TMSDWebImage/TMSDImageIOAnimatedCoderInternal.h>
#import <TMSDWebImage/TMSDImageGIFCoder.h>
#import <TMSDWebImage/TMSDImageAPNGCoder.h>
#import <TMSDWebImage/TMSDImageHEICCoder.h>
#import <TMSDWebImage/TMSDImageAWebPCoder.h>

@implementation TMSDAnimatedImageRep {
    CGImageSourceRef _imageSource;
}

- (void)dealloc {
    if (_imageSource) {
        CFRelease(_imageSource);
        _imageSource = NULL;
    }
}

- (instancetype)copyWithZone:(NSZone *)zone {
  TMSDAnimatedImageRep *imageRep = [super copyWithZone:zone];
  CFRetain(imageRep->_imageSource);
  return imageRep;
}

// `NSBitmapImageRep`'s `imageRepWithData:` is not designed initializer
+ (instancetype)imageRepWithData:(NSData *)data {
    TMSDAnimatedImageRep *imageRep = [[TMSDAnimatedImageRep alloc] initWithData:data];
    return imageRep;
}

// We should override init method for `NSBitmapImageRep` to do initialize about animated image format
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunguarded-availability"
- (instancetype)initWithData:(NSData *)data {
    self = [super initWithData:data];
    if (self) {
        CGImageSourceRef imageSource = CGImageSourceCreateWithData((__bridge CFDataRef) data, NULL);
        if (!imageSource) {
            return self;
        }
        _imageSource = imageSource;
        NSUInteger frameCount = CGImageSourceGetCount(imageSource);
        if (frameCount <= 1) {
            return self;
        }
        CFStringRef type = CGImageSourceGetType(imageSource);
        if (!type) {
            return self;
        }
        if (CFStringCompare(type, kSDUTTypeGIF, 0) == kCFCompareEqualTo) {
            // GIF
            // Fix the `NSBitmapImageRep` GIF loop count calculation issue
            // Which will use 0 when there are no loop count information metadata in GIF data
            NSUInteger loopCount = [TMSDImageGIFCoder imageLoopCountWithSource:imageSource];
            [self setProperty:NSImageLoopCount withValue:@(loopCount)];
        } else if (CFStringCompare(type, kSDUTTypePNG, 0) == kCFCompareEqualTo) {
            // APNG
            // Do initialize about frame count, current frame/duration and loop count
            [self setProperty:NSImageFrameCount withValue:@(frameCount)];
            [self setProperty:NSImageCurrentFrame withValue:@(0)];
            NSUInteger loopCount = [TMSDImageAPNGCoder imageLoopCountWithSource:imageSource];
            [self setProperty:NSImageLoopCount withValue:@(loopCount)];
        } else if (CFStringCompare(type, kSDUTTypeHEICS, 0) == kCFCompareEqualTo) {
            // HEIC
            // Do initialize about frame count, current frame/duration and loop count
            [self setProperty:NSImageFrameCount withValue:@(frameCount)];
            [self setProperty:NSImageCurrentFrame withValue:@(0)];
            NSUInteger loopCount = [TMSDImageHEICCoder imageLoopCountWithSource:imageSource];
            [self setProperty:NSImageLoopCount withValue:@(loopCount)];
        } else if (CFStringCompare(type, kSDUTTypeWebP, 0) == kCFCompareEqualTo) {
            // WebP
            // Do initialize about frame count, current frame/duration and loop count
            [self setProperty:NSImageFrameCount withValue:@(frameCount)];
            [self setProperty:NSImageCurrentFrame withValue:@(0)];
            NSUInteger loopCount = [TMSDImageAWebPCoder imageLoopCountWithSource:imageSource];
            [self setProperty:NSImageLoopCount withValue:@(loopCount)];
        }
    }
    return self;
}

// `NSBitmapImageRep` will use `kCGImagePropertyGIFDelayTime` whenever you call `setProperty:withValue:` with `NSImageCurrentFrame` to change the current frame. We override it and use the actual `kCGImagePropertyGIFUnclampedDelayTime` if need.
- (void)setProperty:(NSBitmapImageRepPropertyKey)property withValue:(id)value {
    [super setProperty:property withValue:value];
    if ([property isEqualToString:NSImageCurrentFrame]) {
        // Access the image source
        CGImageSourceRef imageSource = _imageSource;
        if (!imageSource) {
            return;
        }
        // Check format type
        CFStringRef type = CGImageSourceGetType(imageSource);
        if (!type) {
            return;
        }
        NSUInteger index = [value unsignedIntegerValue];
        NSTimeInterval frameDuration = 0;
        if (CFStringCompare(type, kSDUTTypeGIF, 0) == kCFCompareEqualTo) {
            // GIF
            frameDuration = [TMSDImageGIFCoder frameDurationAtIndex:index source:imageSource];
        } else if (CFStringCompare(type, kSDUTTypePNG, 0) == kCFCompareEqualTo) {
            // APNG
            frameDuration = [TMSDImageAPNGCoder frameDurationAtIndex:index source:imageSource];
        } else if (CFStringCompare(type, kSDUTTypeHEICS, 0) == kCFCompareEqualTo) {
            // HEIC
            frameDuration = [TMSDImageHEICCoder frameDurationAtIndex:index source:imageSource];
        } else if (CFStringCompare(type, kSDUTTypeWebP, 0) == kCFCompareEqualTo) {
            // WebP
            frameDuration = [TMSDImageAWebPCoder frameDurationAtIndex:index source:imageSource];
        }
        if (!frameDuration) {
            return;
        }
        // Reset super frame duration with the actual frame duration
        [super setProperty:NSImageCurrentFrameDuration withValue:@(frameDuration)];
    }
}
#pragma clang diagnostic pop

@end

#endif
