/*
 * This file is part of the TMSDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import <TMSDWebImage/TMSDWebImageCompat.h>
#import <TMSDWebImage/NSData+ImageContentType.h>
#import <TMSDWebImage/TMSDImageCoder.h>

/**
 UIImage category for image metadata, including animation, loop count, format, incremental, etc.
 */
@interface UIImage (TMSDMetadata)

/**
 * UIKit:
 * For static image format, this value is always 0.
 * For animated image format, 0 means infinite looping.
 * Note that because of the limitations of categories this property can get out of sync if you create another instance with CGImage or other methods.
 * AppKit:
 * NSImage currently only support animated via `NSBitmapImageRep`(GIF) or `TMSDAnimatedImageRep`(APNG/GIF/WebP) unlike UIImage.
 * The getter of this property will get the loop count from animated imageRep
 * The setter of this property will set the loop count from animated imageRep
 */
@property (nonatomic, assign) NSUInteger tmsd_imageLoopCount;

/**
 * UIKit:
 * Returns the `images`'s count by unapply the patch for the different frame durations. Which matches the real visible frame count when displaying on UIImageView.
 * See more in `TMSDImageCoderHelper.animatedImageWithFrames`.
 * Returns 1 for static image.
 * AppKit:
 * Returns the underlaying `NSBitmapImageRep` or `TMSDAnimatedImageRep` frame count.
 * Returns 1 for static image.
 */
@property (nonatomic, assign, readonly) NSUInteger tmsd_imageFrameCount;

/**
 * UIKit:
 * Check the `images` array property.
 * AppKit:
 * NSImage currently only support animated via GIF imageRep unlike UIImage. It will check the imageRep's frame count.
 */
@property (nonatomic, assign, readonly) BOOL tmsd_isAnimated;

/**
 * UIKit:
 * Check the `isSymbolImage` property. Also check the system PDF(iOS 11+) && SVG(iOS 13+) support.
 * AppKit:
 * NSImage supports PDF && SVG && EPS imageRep, check the imageRep class.
 */
@property (nonatomic, assign, readonly) BOOL tmsd_isVector;

/**
 * The image format represent the original compressed image data format.
 * If you don't manually specify a format, this information is retrieve from CGImage using `CGImageGetUTType`, which may return nil for non-CG based image. At this time it will return `TMSDImageFormatUndefined` as default value.
 * @note Note that because of the limitations of categories this property can get out of sync if you create another instance with CGImage or other methods.
 */
@property (nonatomic, assign) TMSDImageFormat tmsd_imageFormat;

/**
 A bool value indicating whether the image is during incremental decoding and may not contains full pixels.
 */
@property (nonatomic, assign) BOOL tmsd_isIncremental;

/**
 A dictionary value contains the decode options when decoded from TMSDWebImage loading system (say, `TMSDImageCacheDecodeImageData/TMSDImageLoaderDecode[Progressive]ImageData`)
 It may not always available and only image decoding related options will be saved. (including [.decodeScaleFactor, .decodeThumbnailPixelSize, .decodePreserveAspectRatio, .decodeFirstFrameOnly])
 @note This is used to identify and check the image from downloader when multiple different request (which want different image thumbnail size, image class, etc) share the same URLOperation.
 @warning This API exist only because of current TMSDWebImageDownloader bad design which does not callback the context we call it. There will be refactory in future (API break) and you SHOULD NOT rely on this property at all.
 */
@property (nonatomic, copy) TMSDImageCoderOptions *tmsd_decodeOptions;

@end
