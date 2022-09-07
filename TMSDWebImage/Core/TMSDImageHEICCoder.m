/*
* This file is part of the TMSDWebImage package.
* (c) Olivier Poitrey <rs@dailymotion.com>
*
* For the full copyright and license information, please view the LICENSE
* file that was distributed with this source code.
*/

#import <TMSDWebImage/TMSDImageHEICCoder.h>
#import <TMSDWebImage/TMSDImageIOAnimatedCoderInternal.h>

// These constants are available from iOS 13+ and Xcode 11. This raw value is used for toolchain and firmware compatibility
static NSString * kSDCGImagePropertyHEICSDictionary = @"{HEICS}";
static NSString * kSDCGImagePropertyHEICSLoopCount = @"LoopCount";
static NSString * kSDCGImagePropertyHEICSDelayTime = @"DelayTime";
static NSString * kSDCGImagePropertyHEICSUnclampedDelayTime = @"UnclampedDelayTime";

@implementation TMSDImageHEICCoder

+ (void)initialize {
    if (@available(iOS 13, tvOS 13, macOS 10.15, watchOS 6, *)) {
        // Use TMSDK instead of raw value
        kSDCGImagePropertyHEICSDictionary = (__bridge NSString *)kCGImagePropertyHEICSDictionary;
        kSDCGImagePropertyHEICSLoopCount = (__bridge NSString *)kCGImagePropertyHEICSLoopCount;
        kSDCGImagePropertyHEICSDelayTime = (__bridge NSString *)kCGImagePropertyHEICSDelayTime;
        kSDCGImagePropertyHEICSUnclampedDelayTime = (__bridge NSString *)kCGImagePropertyHEICSUnclampedDelayTime;
    }
}

+ (instancetype)sharedCoder {
    static TMSDImageHEICCoder *coder;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        coder = [[TMSDImageHEICCoder alloc] init];
    });
    return coder;
}

#pragma mark - TMSDImageCoder

- (BOOL)canDecodeFromData:(nullable NSData *)data {
    switch ([NSData tmsd_imageFormatForImageData:data]) {
        case TMSDImageFormatHEIC:
            // Check HEIC decoding compatibility
            return [self.class canDecodeFromFormat:TMSDImageFormatHEIC];
        case TMSDImageFormatHEIF:
            // Check HEIF decoding compatibility
            return [self.class canDecodeFromFormat:TMSDImageFormatHEIF];
        default:
            return NO;
    }
}

- (BOOL)canIncrementalDecodeFromData:(NSData *)data {
    return [self canDecodeFromData:data];
}

- (BOOL)canEncodeToFormat:(TMSDImageFormat)format {
    switch (format) {
        case TMSDImageFormatHEIC:
            // Check HEIC encoding compatibility
            return [self.class canEncodeToFormat:TMSDImageFormatHEIC];
        case TMSDImageFormatHEIF:
            // Check HEIF encoding compatibility
            return [self.class canEncodeToFormat:TMSDImageFormatHEIF];
        default:
            return NO;
    }
}

#pragma mark - Subclass Override

+ (TMSDImageFormat)imageFormat {
    return TMSDImageFormatHEIC;
}

+ (NSString *)imageUTType {
    return (__bridge NSString *)kSDUTTypeHEIC;
}

+ (NSString *)dictionaryProperty {
    return kSDCGImagePropertyHEICSDictionary;
}

+ (NSString *)unclampedDelayTimeProperty {
    return kSDCGImagePropertyHEICSUnclampedDelayTime;
}

+ (NSString *)delayTimeProperty {
    return kSDCGImagePropertyHEICSDelayTime;
}

+ (NSString *)loopCountProperty {
    return kSDCGImagePropertyHEICSLoopCount;
}

+ (NSUInteger)defaultLoopCount {
    return 0;
}

@end
