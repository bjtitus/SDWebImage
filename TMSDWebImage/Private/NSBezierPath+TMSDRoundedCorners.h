/*
 * This file is part of the TMSDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import <TMSDWebImage/TMSDWebImageCompat.h>

#if TMSD_MAC

#import <TMSDWebImage/UIImage+Transform.h>

@interface NSBezierPath (TMSDTMSDRoundedCorners)

/**
 Convenience way to create a bezier path with the specify rounding corners on macOS. Same as the one on `UIBezierPath`.
 */
+ (nonnull instancetype)tmsd_bezierPathWithRoundedRect:(NSRect)rect byRoundingCorners:(TMSDRectCorner)corners cornerRadius:(CGFloat)cornerRadius;

@end

#endif
