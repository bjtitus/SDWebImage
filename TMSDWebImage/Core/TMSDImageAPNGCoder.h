/*
 * This file is part of the TMSDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import <Foundation/Foundation.h>
#import <TMSDWebImage/TMSDImageIOAnimatedCoder.h>

/**
 Built in coder using ImageIO that supports APNG encoding/decoding
 */
@interface TMSDImageAPNGCoder : TMSDImageIOAnimatedCoder <TMSDProgressiveImageCoder, TMSDAnimatedImageCoder>

@property (nonatomic, class, readonly, nonnull) TMSDImageAPNGCoder *sharedCoder;

@end
