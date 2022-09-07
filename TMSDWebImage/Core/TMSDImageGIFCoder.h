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
 Built in coder using ImageIO that supports animated GIF encoding/decoding
 @note `TMSDImageIOCoder` supports GIF but only as static (will use the 1st frame).
 @note Use `TMSDImageGIFCoder` for fully animated GIFs. For `UIImageView`, it will produce animated `UIImage`(`NSImage` on macOS) for rendering. For `TMSDAnimatedImageView`, it will use `TMSDAnimatedImage` for rendering.
 @note The recommended approach for animated GIFs is using `TMSDAnimatedImage` with `TMSDAnimatedImageView`. It's more performant than `UIImageView` for GIF displaying(especially on memory usage)
 */
@interface TMSDImageGIFCoder : TMSDImageIOAnimatedCoder <TMSDProgressiveImageCoder, TMSDAnimatedImageCoder>

@property (nonatomic, class, readonly, nonnull) TMSDImageGIFCoder *sharedCoder;

@end
