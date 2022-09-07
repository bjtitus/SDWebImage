/*
 * This file is part of the TMSDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import <TMSDWebImage/TMSDImageCodersManager.h>
#import <TMSDWebImage/TMSDImageIOCoder.h>
#import <TMSDWebImage/TMSDImageGIFCoder.h>
#import <TMSDWebImage/TMSDImageAPNGCoder.h>
#import <TMSDWebImage/TMSDImageHEICCoder.h>
#import <TMSDWebImage/TMSDInternalMacros.h>

@interface TMSDImageCodersManager ()

@property (nonatomic, strong, nonnull) NSMutableArray<id<TMSDImageCoder>> *imageCoders;

@end

@implementation TMSDImageCodersManager {
    TMSD_LOCK_DECLARE(_codersLock);
}

+ (nonnull instancetype)sharedManager {
    static dispatch_once_t once;
    static id instance;
    dispatch_once(&once, ^{
        instance = [self new];
    });
    return instance;
}

- (instancetype)init {
    if (self = [super init]) {
        // initialize with default coders
        _imageCoders = [NSMutableArray arrayWithArray:@[[TMSDImageIOCoder sharedCoder], [TMSDImageGIFCoder sharedCoder], [TMSDImageAPNGCoder sharedCoder]]];
        TMSD_LOCK_INIT(_codersLock);
    }
    return self;
}

- (NSArray<id<TMSDImageCoder>> *)coders {
    TMSD_LOCK(_codersLock);
    NSArray<id<TMSDImageCoder>> *coders = [_imageCoders copy];
    TMSD_UNLOCK(_codersLock);
    return coders;
}

- (void)setCoders:(NSArray<id<TMSDImageCoder>> *)coders {
    TMSD_LOCK(_codersLock);
    [_imageCoders removeAllObjects];
    if (coders.count) {
        [_imageCoders addObjectsFromArray:coders];
    }
    TMSD_UNLOCK(_codersLock);
}

#pragma mark - Coder IO operations

- (void)addCoder:(nonnull id<TMSDImageCoder>)coder {
    if (![coder conformsToProtocol:@protocol(TMSDImageCoder)]) {
        return;
    }
    TMSD_LOCK(_codersLock);
    [_imageCoders addObject:coder];
    TMSD_UNLOCK(_codersLock);
}

- (void)removeCoder:(nonnull id<TMSDImageCoder>)coder {
    if (![coder conformsToProtocol:@protocol(TMSDImageCoder)]) {
        return;
    }
    TMSD_LOCK(_codersLock);
    [_imageCoders removeObject:coder];
    TMSD_UNLOCK(_codersLock);
}

#pragma mark - TMSDImageCoder
- (BOOL)canDecodeFromData:(NSData *)data {
    NSArray<id<TMSDImageCoder>> *coders = self.coders;
    for (id<TMSDImageCoder> coder in coders.reverseObjectEnumerator) {
        if ([coder canDecodeFromData:data]) {
            return YES;
        }
    }
    return NO;
}

- (BOOL)canEncodeToFormat:(TMSDImageFormat)format {
    NSArray<id<TMSDImageCoder>> *coders = self.coders;
    for (id<TMSDImageCoder> coder in coders.reverseObjectEnumerator) {
        if ([coder canEncodeToFormat:format]) {
            return YES;
        }
    }
    return NO;
}

- (UIImage *)decodedImageWithData:(NSData *)data options:(nullable TMSDImageCoderOptions *)options {
    if (!data) {
        return nil;
    }
    UIImage *image;
    NSArray<id<TMSDImageCoder>> *coders = self.coders;
    for (id<TMSDImageCoder> coder in coders.reverseObjectEnumerator) {
        if ([coder canDecodeFromData:data]) {
            image = [coder decodedImageWithData:data options:options];
            break;
        }
    }
    
    return image;
}

- (NSData *)encodedDataWithImage:(UIImage *)image format:(TMSDImageFormat)format options:(nullable TMSDImageCoderOptions *)options {
    if (!image) {
        return nil;
    }
    NSArray<id<TMSDImageCoder>> *coders = self.coders;
    for (id<TMSDImageCoder> coder in coders.reverseObjectEnumerator) {
        if ([coder canEncodeToFormat:format]) {
            return [coder encodedDataWithImage:image format:format options:options];
        }
    }
    return nil;
}

@end
