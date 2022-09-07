/*
 * This file is part of the TMSDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import <TMSDWebImage/TMSDWebImageCompat.h>

#if TMSD_MAC

/**
 A subclass of `NSBitmapImageRep` to fix that GIF duration issue because `NSBitmapImageRep` will reset `NSImageCurrentFrameDuration` by using `kCGImagePropertyGIFDelayTime` but not `kCGImagePropertyGIFUnclampedDelayTime`.
 This also fix the GIF loop count issue, which will use the Netscape standard (See http://www6.uniovi.es/gifanim/gifabout.htm)  to only place once when the `kCGImagePropertyGIFLoopCount` is nil. This is what modern browser's behavior.
 Built in GIF coder use this instead of `NSBitmapImageRep` for better GIF rendering. If you do not want this, only enable `TMSDImageIOCoder`, which just call `NSImage` API and actually use `NSBitmapImageRep` for GIF image.
 This also support APNG format using `TMSDImageAPNGCoder`. Which provide full alpha-channel support and the correct duration match the `kCGImagePropertyAPNGUnclampedDelayTime`.
 */
@interface TMSDAnimatedImageRep : NSBitmapImageRep

@end

#endif
