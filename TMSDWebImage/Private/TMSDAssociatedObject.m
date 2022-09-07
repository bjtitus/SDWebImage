/*
* This file is part of the TMSDWebImage package.
* (c) Olivier Poitrey <rs@dailymotion.com>
*
* For the full copyright and license information, please view the LICENSE
* file that was distributed with this source code.
*/

#import <TMSDWebImage/TMSDAssociatedObject.h>
#import <TMSDWebImage/UIImage+Metadata.h>
#import <TMSDWebImage/UIImage+ExtendedCacheData.h>
#import <TMSDWebImage/UIImage+MemoryCacheCost.h>
#import <TMSDWebImage/UIImage+ForceDecode.h>

void TMSDImageCopyAssociatedObject(UIImage * _Nullable source, UIImage * _Nullable target) {
    if (!source || !target) {
        return;
    }
    // Image Metadata
    target.tmsd_isIncremental = source.tmsd_isIncremental;
    target.tmsd_decodeOptions = source.tmsd_decodeOptions;
    target.tmsd_imageLoopCount = source.tmsd_imageLoopCount;
    target.tmsd_imageFormat = source.tmsd_imageFormat;
    // Force Decode
    target.tmsd_isDecoded = source.tmsd_isDecoded;
    // Extended Cache Data
    target.tmsd_extendedObject = source.tmsd_extendedObject;
}
