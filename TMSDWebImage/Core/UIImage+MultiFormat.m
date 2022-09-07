/*
 * This file is part of the TMSDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import <TMSDWebImage/UIImage+MultiFormat.h>
#import <TMSDWebImage/TMSDImageCodersManager.h>

@implementation UIImage (TMSDMultiFormat)

+ (nullable UIImage *)tmsd_imageWithData:(nullable NSData *)data {
    return [self tmsd_imageWithData:data scale:1];
}

+ (nullable UIImage *)tmsd_imageWithData:(nullable NSData *)data scale:(CGFloat)scale {
    return [self tmsd_imageWithData:data scale:scale firstFrameOnly:NO];
}

+ (nullable UIImage *)tmsd_imageWithData:(nullable NSData *)data scale:(CGFloat)scale firstFrameOnly:(BOOL)firstFrameOnly {
    if (!data) {
        return nil;
    }
    TMSDImageCoderOptions *options = @{TMSDImageCoderDecodeScaleFactor : @(MAX(scale, 1)), TMSDImageCoderDecodeFirstFrameOnly : @(firstFrameOnly)};
    return [[TMSDImageCodersManager sharedManager] decodedImageWithData:data options:options];
}

- (nullable NSData *)tmsd_imageData {
    return [self tmsd_imageDataAsFormat:TMSDImageFormatUndefined];
}

- (nullable NSData *)tmsd_imageDataAsFormat:(TMSDImageFormat)imageFormat {
    return [self tmsd_imageDataAsFormat:imageFormat compressionQuality:1];
}

- (nullable NSData *)tmsd_imageDataAsFormat:(TMSDImageFormat)imageFormat compressionQuality:(double)compressionQuality {
    return [self tmsd_imageDataAsFormat:imageFormat compressionQuality:compressionQuality firstFrameOnly:NO];
}

- (nullable NSData *)tmsd_imageDataAsFormat:(TMSDImageFormat)imageFormat compressionQuality:(double)compressionQuality firstFrameOnly:(BOOL)firstFrameOnly {
    TMSDImageCoderOptions *options = @{TMSDImageCoderEncodeCompressionQuality : @(compressionQuality), TMSDImageCoderEncodeFirstFrameOnly : @(firstFrameOnly)};
    return [[TMSDImageCodersManager sharedManager] encodedDataWithImage:self format:imageFormat options:options];
}

@end
