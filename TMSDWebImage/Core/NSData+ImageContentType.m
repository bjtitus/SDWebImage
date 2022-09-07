/*
 * This file is part of the TMSDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 * (c) Fabrice Aneche
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import <TMSDWebImage/NSData+ImageContentType.h>
#if TMSD_MAC
#import <CoreServices/CoreServices.h>
#else
#import <MobileCoreServices/MobileCoreServices.h>
#endif
#import <TMSDWebImage/TMSDImageIOAnimatedCoderInternal.h>

#define kSVGTagEnd @"</svg>"

@implementation NSData (TMSDImageContentType)

+ (TMSDImageFormat)tmsd_imageFormatForImageData:(nullable NSData *)data {
    if (!data) {
        return TMSDImageFormatUndefined;
    }
    
    // File signatures table: http://www.garykessler.net/library/file_sigs.html
    uint8_t c;
    [data getBytes:&c length:1];
    switch (c) {
        case 0xFF:
            return TMSDImageFormatJPEG;
        case 0x89:
            return TMSDImageFormatPNG;
        case 0x47:
            return TMSDImageFormatGIF;
        case 0x49:
        case 0x4D:
            return TMSDImageFormatTIFF;
        case 0x52: {
            if (data.length >= 12) {
                //RIFF....WEBP
                NSString *testString = [[NSString alloc] initWithData:[data subdataWithRange:NSMakeRange(0, 12)] encoding:NSASCIIStringEncoding];
                if ([testString hasPrefix:@"RIFF"] && [testString hasSuffix:@"WEBP"]) {
                    return TMSDImageFormatWebP;
                }
            }
            break;
        }
        case 0x00: {
            if (data.length >= 12) {
                //....ftypheic ....ftypheix ....ftyphevc ....ftyphevx
                NSString *testString = [[NSString alloc] initWithData:[data subdataWithRange:NSMakeRange(4, 8)] encoding:NSASCIIStringEncoding];
                if ([testString isEqualToString:@"ftypheic"]
                    || [testString isEqualToString:@"ftypheix"]
                    || [testString isEqualToString:@"ftyphevc"]
                    || [testString isEqualToString:@"ftyphevx"]) {
                    return TMSDImageFormatHEIC;
                }
                //....ftypmif1 ....ftypmsf1
                if ([testString isEqualToString:@"ftypmif1"] || [testString isEqualToString:@"ftypmsf1"]) {
                    return TMSDImageFormatHEIF;
                }
            }
            break;
        }
        case 0x25: {
            if (data.length >= 4) {
                //%PDF
                NSString *testString = [[NSString alloc] initWithData:[data subdataWithRange:NSMakeRange(1, 3)] encoding:NSASCIIStringEncoding];
                if ([testString isEqualToString:@"PDF"]) {
                    return TMSDImageFormatPDF;
                }
            }
        }
        case 0x3C: {
            // Check end with SVG tag
            if ([data rangeOfData:[kSVGTagEnd dataUsingEncoding:NSUTF8StringEncoding] options:NSDataSearchBackwards range: NSMakeRange(data.length - MIN(100, data.length), MIN(100, data.length))].location != NSNotFound) {
                return TMSDImageFormatSVG;
            }
        }
    }
    return TMSDImageFormatUndefined;
}

+ (nonnull CFStringRef)tmsd_UTTypeFromImageFormat:(TMSDImageFormat)format {
    CFStringRef UTType;
    switch (format) {
        case TMSDImageFormatJPEG:
            UTType = kSDUTTypeJPEG;
            break;
        case TMSDImageFormatPNG:
            UTType = kSDUTTypePNG;
            break;
        case TMSDImageFormatGIF:
            UTType = kSDUTTypeGIF;
            break;
        case TMSDImageFormatTIFF:
            UTType = kSDUTTypeTIFF;
            break;
        case TMSDImageFormatWebP:
            UTType = kSDUTTypeWebP;
            break;
        case TMSDImageFormatHEIC:
            UTType = kSDUTTypeHEIC;
            break;
        case TMSDImageFormatHEIF:
            UTType = kSDUTTypeHEIF;
            break;
        case TMSDImageFormatPDF:
            UTType = kSDUTTypePDF;
            break;
        case TMSDImageFormatSVG:
            UTType = kSDUTTypeSVG;
            break;
        default:
            // default is kUTTypeImage abstract type
            UTType = kSDUTTypeImage;
            break;
    }
    return UTType;
}

+ (TMSDImageFormat)tmsd_imageFormatFromUTType:(CFStringRef)uttype {
    if (!uttype) {
        return TMSDImageFormatUndefined;
    }
    TMSDImageFormat imageFormat;
    if (CFStringCompare(uttype, kSDUTTypeJPEG, 0) == kCFCompareEqualTo) {
        imageFormat = TMSDImageFormatJPEG;
    } else if (CFStringCompare(uttype, kSDUTTypePNG, 0) == kCFCompareEqualTo) {
        imageFormat = TMSDImageFormatPNG;
    } else if (CFStringCompare(uttype, kSDUTTypeGIF, 0) == kCFCompareEqualTo) {
        imageFormat = TMSDImageFormatGIF;
    } else if (CFStringCompare(uttype, kSDUTTypeTIFF, 0) == kCFCompareEqualTo) {
        imageFormat = TMSDImageFormatTIFF;
    } else if (CFStringCompare(uttype, kSDUTTypeWebP, 0) == kCFCompareEqualTo) {
        imageFormat = TMSDImageFormatWebP;
    } else if (CFStringCompare(uttype, kSDUTTypeHEIC, 0) == kCFCompareEqualTo) {
        imageFormat = TMSDImageFormatHEIC;
    } else if (CFStringCompare(uttype, kSDUTTypeHEIF, 0) == kCFCompareEqualTo) {
        imageFormat = TMSDImageFormatHEIF;
    } else if (CFStringCompare(uttype, kSDUTTypePDF, 0) == kCFCompareEqualTo) {
        imageFormat = TMSDImageFormatPDF;
    } else if (CFStringCompare(uttype, kSDUTTypeSVG, 0) == kCFCompareEqualTo) {
        imageFormat = TMSDImageFormatSVG;
    } else {
        imageFormat = TMSDImageFormatUndefined;
    }
    return imageFormat;
}

@end
