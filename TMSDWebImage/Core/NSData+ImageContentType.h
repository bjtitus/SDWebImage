/*
 * This file is part of the TMSDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 * (c) Fabrice Aneche
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import <Foundation/Foundation.h>
#import <TMSDWebImage/TMSDWebImageCompat.h>

/**
 You can use switch case like normal enum. It's also recommended to add a default case. You should not assume anything about the raw value.
 For custom coder plugin, it can also extern the enum for supported format. See `TMSDImageCoder` for more detailed information.
 */
typedef NSInteger TMSDImageFormat NS_TYPED_EXTENSIBLE_ENUM;
static const TMSDImageFormat TMSDImageFormatUndefined = -1;
static const TMSDImageFormat TMSDImageFormatJPEG      = 0;
static const TMSDImageFormat TMSDImageFormatPNG       = 1;
static const TMSDImageFormat TMSDImageFormatGIF       = 2;
static const TMSDImageFormat TMSDImageFormatTIFF      = 3;
static const TMSDImageFormat TMSDImageFormatWebP      = 4;
static const TMSDImageFormat TMSDImageFormatHEIC      = 5;
static const TMSDImageFormat TMSDImageFormatHEIF      = 6;
static const TMSDImageFormat TMSDImageFormatPDF       = 7;
static const TMSDImageFormat TMSDImageFormatSVG       = 8;

/**
 NSData category about the image content type and UTI.
 */
@interface NSData (TMSDImageContentType)

/**
 *  Return image format
 *
 *  @param data the input image data
 *
 *  @return the image format as `TMSDImageFormat` (enum)
 */
+ (TMSDImageFormat)tmsd_imageFormatForImageData:(nullable NSData *)data;

/**
 *  Convert TMSDImageFormat to UTType
 *
 *  @param format Format as TMSDImageFormat
 *  @return The UTType as CFStringRef
 *  @note For unknown format, `kSDUTTypeImage` abstract type will return
 */
+ (nonnull CFStringRef)tmsd_UTTypeFromImageFormat:(TMSDImageFormat)format CF_RETURNS_NOT_RETAINED NS_SWIFT_NAME(tmsd_UTType(from:));

/**
 *  Convert UTType to TMSDImageFormat
 *
 *  @param uttype The UTType as CFStringRef
 *  @return The Format as TMSDImageFormat
 *  @note For unknown type, `TMSDImageFormatUndefined` will return
 */
+ (TMSDImageFormat)tmsd_imageFormatFromUTType:(nonnull CFStringRef)uttype;

@end
