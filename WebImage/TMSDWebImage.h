/*
 * This file is part of the TMSDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 * (c) Florent Vilmart
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import <TMSDWebImage/TMSDWebImageCompat.h>

//! Project version number for TMSDWebImage.
FOUNDATION_EXPORT double TMSDWebImageVersionNumber;

//! Project version string for TMSDWebImage.
FOUNDATION_EXPORT const unsigned char TMSDWebImageVersionString[];

// In this header, you should import all the public headers of your framework using statements like #import <TMSDWebImage/PublicHeader.h>

#import <TMSDWebImage/TMSDWebImageManager.h>
#import <TMSDWebImage/TMSDWebImageCacheKeyFilter.h>
#import <TMSDWebImage/TMSDWebImageCacheSerializer.h>
#import <TMSDWebImage/TMSDImageCacheConfig.h>
#import <TMSDWebImage/TMSDImageCache.h>
#import <TMSDWebImage/TMSDMemoryCache.h>
#import <TMSDWebImage/TMSDDiskCache.h>
#import <TMSDWebImage/TMSDImageCacheDefine.h>
#import <TMSDWebImage/TMSDImageCachesManager.h>
#import <TMSDWebImage/UIView+WebCache.h>
#import <TMSDWebImage/UIImageView+WebCache.h>
#import <TMSDWebImage/UIImageView+HighlightedWebCache.h>
#import <TMSDWebImage/TMSDWebImageDownloaderConfig.h>
#import <TMSDWebImage/TMSDWebImageDownloaderOperation.h>
#import <TMSDWebImage/TMSDWebImageDownloaderRequestModifier.h>
#import <TMSDWebImage/TMSDWebImageDownloaderResponseModifier.h>
#import <TMSDWebImage/TMSDWebImageDownloaderDecryptor.h>
#import <TMSDWebImage/TMSDImageLoader.h>
#import <TMSDWebImage/TMSDImageLoadersManager.h>
#import <TMSDWebImage/UIButton+WebCache.h>
#import <TMSDWebImage/TMSDWebImagePrefetcher.h>
#import <TMSDWebImage/UIView+WebCacheOperation.h>
#import <TMSDWebImage/UIImage+Metadata.h>
#import <TMSDWebImage/UIImage+MultiFormat.h>
#import <TMSDWebImage/UIImage+MemoryCacheCost.h>
#import <TMSDWebImage/UIImage+ExtendedCacheData.h>
#import <TMSDWebImage/TMSDWebImageOperation.h>
#import <TMSDWebImage/TMSDWebImageDownloader.h>
#import <TMSDWebImage/TMSDWebImageTransition.h>
#import <TMSDWebImage/TMSDWebImageIndicator.h>
#import <TMSDWebImage/TMSDImageTransformer.h>
#import <TMSDWebImage/UIImage+Transform.h>
#import <TMSDWebImage/TMSDAnimatedImage.h>
#import <TMSDWebImage/TMSDAnimatedImageView.h>
#import <TMSDWebImage/TMSDAnimatedImageView+WebCache.h>
#import <TMSDWebImage/TMSDAnimatedImagePlayer.h>
#import <TMSDWebImage/TMSDImageCodersManager.h>
#import <TMSDWebImage/TMSDImageCoder.h>
#import <TMSDWebImage/TMSDImageAPNGCoder.h>
#import <TMSDWebImage/TMSDImageGIFCoder.h>
#import <TMSDWebImage/TMSDImageIOCoder.h>
#import <TMSDWebImage/TMSDImageFrame.h>
#import <TMSDWebImage/TMSDImageCoderHelper.h>
#import <TMSDWebImage/TMSDImageGraphics.h>
#import <TMSDWebImage/TMSDGraphicsImageRenderer.h>
#import <TMSDWebImage/UIImage+GIF.h>
#import <TMSDWebImage/UIImage+ForceDecode.h>
#import <TMSDWebImage/NSData+ImageContentType.h>
#import <TMSDWebImage/TMSDWebImageDefine.h>
#import <TMSDWebImage/TMSDWebImageError.h>
#import <TMSDWebImage/TMSDWebImageOptionsProcessor.h>
#import <TMSDWebImage/TMSDImageIOAnimatedCoder.h>
#import <TMSDWebImage/TMSDImageHEICCoder.h>
#import <TMSDWebImage/TMSDImageAWebPCoder.h>

// Mac
#if __has_include(<TMSDWebImage/NSImage+Compatibility.h>)
#import <TMSDWebImage/NSImage+Compatibility.h>
#endif
#if __has_include(<TMSDWebImage/NSButton+WebCache.h>)
#import <TMSDWebImage/NSButton+WebCache.h>
#endif
#if __has_include(<TMSDWebImage/TMSDAnimatedImageRep.h>)
#import <TMSDWebImage/TMSDAnimatedImageRep.h>
#endif

// MapKit
#if __has_include(<TMSDWebImage/MKAnnotationView+WebCache.h>)
#import <TMSDWebImage/MKAnnotationView+WebCache.h>
#endif
