/*
 * This file is part of the TMSDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 * (c) Laurin Brandner
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import <TMSDWebImage/UIImage+GIF.h>
#import <TMSDWebImage/TMSDImageGIFCoder.h>

@implementation UIImage (TMSDGIF)

+ (nullable UIImage *)tmsd_imageWithGIFData:(nullable NSData *)data {
    if (!data) {
        return nil;
    }
    return [[TMSDImageGIFCoder sharedCoder] decodedImageWithData:data options:0];
}

@end
