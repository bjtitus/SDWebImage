/*
 * This file is part of the TMSDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import <TMSDWebImage/UIImage+MemoryCacheCost.h>
#import "objc/runtime.h"
#import <TMSDWebImage/NSImage+Compatibility.h>

FOUNDATION_STATIC_INLINE NSUInteger TMSDMemoryCacheCostForImage(UIImage *image) {
    CGImageRef imageRef = image.CGImage;
    if (!imageRef) {
        return 0;
    }
    NSUInteger bytesPerFrame = CGImageGetBytesPerRow(imageRef) * CGImageGetHeight(imageRef);
    NSUInteger frameCount;
#if TMSD_MAC
    frameCount = 1;
#elif TMSD_UIKIT || TMSD_WATCH
    // Filter the same frame in `_UIAnimatedImage`.
    frameCount = image.images.count > 1 ? [NSSet setWithArray:image.images].count : 1;
#endif
    NSUInteger cost = bytesPerFrame * frameCount;
    return cost;
}

@implementation UIImage (TMSDMemoryCacheCost)

- (NSUInteger)tmsd_memoryCost {
    NSNumber *value = objc_getAssociatedObject(self, @selector(tmsd_memoryCost));
    NSUInteger memoryCost;
    if (value != nil) {
        memoryCost = [value unsignedIntegerValue];
    } else {
        memoryCost = TMSDMemoryCacheCostForImage(self);
    }
    return memoryCost;
}

- (void)setTmsd_memoryCost:(NSUInteger)tmsd_memoryCost {
    objc_setAssociatedObject(self, @selector(tmsd_memoryCost), @(tmsd_memoryCost), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end
