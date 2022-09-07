/*
 * This file is part of the TMSDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import <TMSDWebImage/UIImage+ForceDecode.h>
#import <TMSDWebImage/TMSDImageCoderHelper.h>
#import "objc/runtime.h"
#import <TMSDWebImage/NSImage+Compatibility.h>

@implementation UIImage (TMSDForceDecode)

- (BOOL)tmsd_isDecoded {
    NSNumber *value = objc_getAssociatedObject(self, @selector(tmsd_isDecoded));
    if (value != nil) {
        return value.boolValue;
    } else {
        // Assume only CGImage based can use lazy decoding
        CGImageRef cgImage = self.CGImage;
        if (cgImage) {
            CFStringRef uttype = CGImageGetUTType(self.CGImage);
            if (uttype) {
                // Only ImageIO can set `com.apple.ImageIO.imageSourceTypeIdentifier`
                return NO;
            } else {
                // Thumbnail or CGBitmapContext drawn image
                return YES;
            }
        }
    }
    // Assume others as non-decoded
    return NO;
}

- (void)setTmsd_isDecoded:(BOOL)tmsd_isDecoded {
    objc_setAssociatedObject(self, @selector(tmsd_isDecoded), @(tmsd_isDecoded), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

+ (nullable UIImage *)tmsd_decodedImageWithImage:(nullable UIImage *)image {
    if (!image) {
        return nil;
    }
    return [TMSDImageCoderHelper decodedImageWithImage:image];
}

+ (nullable UIImage *)tmsd_decodedAndScaledDownImageWithImage:(nullable UIImage *)image {
    return [self tmsd_decodedAndScaledDownImageWithImage:image limitBytes:0];
}

+ (nullable UIImage *)tmsd_decodedAndScaledDownImageWithImage:(nullable UIImage *)image limitBytes:(NSUInteger)bytes {
    if (!image) {
        return nil;
    }
    return [TMSDImageCoderHelper decodedAndScaledDownImageWithImage:image limitBytes:bytes];
}

@end
