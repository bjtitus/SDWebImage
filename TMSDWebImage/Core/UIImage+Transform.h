/*
 * This file is part of the TMSDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import <TMSDWebImage/TMSDWebImageCompat.h>

typedef NS_ENUM(NSUInteger, TMSDImageScaleMode) {
    TMSDImageScaleModeFill = 0,
    TMSDImageScaleModeAspectFit = 1,
    TMSDImageScaleModeAspectFill = 2
};

#if TMSD_UIKIT || TMSD_WATCH
typedef UIRectCorner TMSDRectCorner;
#else
typedef NS_OPTIONS(NSUInteger, TMSDRectCorner) {
    TMSDRectCornerTopLeft     = 1 << 0,
    TMSDRectCornerTopRight    = 1 << 1,
    TMSDRectCornerBottomLeft  = 1 << 2,
    TMSDRectCornerBottomRight = 1 << 3,
    TMSDRectCornerAllCorners  = ~0UL
};
#endif

/**
 Provide some common method for `UIImage`.
 Image process is based on Core Graphics and vImage.
 */
@interface UIImage (TMSDTransform)

#pragma mark - Image Geometry

/**
 Returns a new image which is resized from this image.
 You can specify a larger or smaller size than the image size. The image content will be changed with the scale mode.
 
 @param size        The new size to be resized, values should be positive.
 @param scaleMode   The scale mode for image content.
 @return The new image with the given size.
 */
- (nullable UIImage *)tmsd_resizedImageWithSize:(CGSize)size scaleMode:(TMSDImageScaleMode)scaleMode;

/**
 Returns a new image which is cropped from this image.
 
 @param rect     Image's inner rect.
 @return         The new image with the cropping rect.
 */
- (nullable UIImage *)tmsd_croppedImageWithRect:(CGRect)rect;

/**
 Rounds a new image with a given corner radius and corners.
 
 @param cornerRadius The radius of each corner oval. Values larger than half the
 rectangle's width or height are clamped appropriately to
 half the width or height.
 @param corners      A bitmask value that identifies the corners that you want
 rounded. You can use this parameter to round only a subset
 of the corners of the rectangle.
 @param borderWidth  The inset border line width. Values larger than half the rectangle's
 width or height are clamped appropriately to half the width
 or height.
 @param borderColor  The border stroke color. nil means clear color.
 @return The new image with the round corner.
 */
- (nullable UIImage *)tmsd_roundedCornerImageWithRadius:(CGFloat)cornerRadius
                                              corners:(TMSDRectCorner)corners
                                          borderWidth:(CGFloat)borderWidth
                                          borderColor:(nullable UIColor *)borderColor;

/**
 Returns a new rotated image (relative to the center).
 
 @param angle     Rotated radians in counterclockwise.⟲
 @param fitSize   YES: new image's size is extend to fit all content.
                  NO: image's size will not change, content may be clipped.
 @return The new image with the rotation.
 */
- (nullable UIImage *)tmsd_rotatedImageWithAngle:(CGFloat)angle fitSize:(BOOL)fitSize;

/**
 Returns a new horizontally(vertically) flipped image.
 
 @param horizontal YES to flip the image horizontally. ⇋
 @param vertical YES to flip the image vertically. ⥯
 @return The new image with the flipping.
 */
- (nullable UIImage *)tmsd_flippedImageWithHorizontal:(BOOL)horizontal vertical:(BOOL)vertical;

#pragma mark - Image Blending

/**
 Return a tinted image with the given color. This actually use alpha blending of current image and the tint color.
 
 @param tintColor  The tint color.
 @return The new image with the tint color.
 */
- (nullable UIImage *)tmsd_tintedImageWithColor:(nonnull UIColor *)tintColor;

/**
 Return the pixel color at specify position. The point is from the top-left to the bottom-right and 0-based. The returned the color is always be RGBA format. The image must be CG-based.
 @note The point's x/y should not be smaller than 0, or greater than or equal to width/height.
 @note The overhead of object creation means this method is best suited for infrequent color sampling. For heavy image processing, grab the raw bitmap data and process yourself.

 @param point The position of pixel
 @return The color for specify pixel, or nil if any error occur
 */
- (nullable UIColor *)tmsd_colorAtPoint:(CGPoint)point;

/**
 Return the pixel color array with specify rectangle. The rect is from the top-left to the bottom-right and 0-based. The returned the color is always be RGBA format. The image must be CG-based.
 @note The rect's width/height should not be smaller than or equal to 0. The minX/minY should not be smaller than 0. The maxX/maxY should not be greater than width/height. Attention this limit is different from `tmsd_colorAtPoint:` (point: (0, 0) like rect: (0, 0, 1, 1))
 @note The overhead of object creation means this method is best suited for infrequent color sampling. For heavy image processing, grab the raw bitmap data and process yourself.

 @param rect The rectangle of pixels
 @return The color array for specify pixels, or nil if any error occur
 */
- (nullable NSArray<UIColor *> *)tmsd_colorsWithRect:(CGRect)rect;

#pragma mark - Image Effect

/**
 Return a new image applied a blur effect.
 
 @param blurRadius     The radius of the blur in points, 0 means no blur effect.
 
 @return               The new image with blur effect, or nil if an error occurs (e.g. no enough memory).
 */
- (nullable UIImage *)tmsd_blurredImageWithRadius:(CGFloat)blurRadius;

#if TMSD_UIKIT || TMSD_MAC
/**
 Return a new image applied a CIFilter.

 @param filter The CIFilter to be applied to the image.
 @return The new image with the CIFilter, or nil if an error occurs (e.g. no
 enough memory).
 */
- (nullable UIImage *)tmsd_filteredImageWithFilter:(nonnull CIFilter *)filter;
#endif

@end
