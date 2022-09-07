/*
* This file is part of the TMSDWebImage package.
* (c) Olivier Poitrey <rs@dailymotion.com>
*
* For the full copyright and license information, please view the LICENSE
* file that was distributed with this source code.
*/

#import <TMSDWebImage/TMSDImageIOAnimatedCoder.h>
#import <TMSDWebImage/NSImage+Compatibility.h>
#import <TMSDWebImage/UIImage+Metadata.h>
#import <TMSDWebImage/NSData+ImageContentType.h>
#import <TMSDWebImage/TMSDImageCoderHelper.h>
#import <TMSDWebImage/TMSDAnimatedImageRep.h>
#import <TMSDWebImage/UIImage+ForceDecode.h>

// Specify DPI for vector format in CGImageSource, like PDF
static NSString * kSDCGImageSourceRasterizationDPI = @"kCGImageSourceRasterizationDPI";
// Specify File Size for lossy format encoding, like JPEG
static NSString * kSDCGImageDestinationRequestedFileSize = @"kCGImageDestinationRequestedFileSize";

@interface TMSDImageIOCoderFrame : NSObject

@property (nonatomic, assign) NSUInteger index; // Frame index (zero based)
@property (nonatomic, assign) NSTimeInterval duration; // Frame duration in seconds

@end

@implementation TMSDImageIOCoderFrame
@end

@implementation TMSDImageIOAnimatedCoder {
    size_t _width, _height;
    CGImageSourceRef _imageSource;
    NSData *_imageData;
    CGFloat _scale;
    NSUInteger _loopCount;
    NSUInteger _frameCount;
    NSArray<TMSDImageIOCoderFrame *> *_frames;
    BOOL _finished;
    BOOL _preserveAspectRatio;
    CGSize _thumbnailSize;
}

- (void)dealloc
{
    if (_imageSource) {
        CFRelease(_imageSource);
        _imageSource = NULL;
    }
#if TMSD_UIKIT
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
#endif
}

- (void)didReceiveMemoryWarning:(NSNotification *)notification
{
    if (_imageSource) {
        for (size_t i = 0; i < _frameCount; i++) {
            CGImageSourceRemoveCacheAtIndex(_imageSource, i);
        }
    }
}

#pragma mark - Subclass Override

+ (TMSDImageFormat)imageFormat {
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:[NSString stringWithFormat:@"For `TMSDImageIOAnimatedCoder` subclass, you must override %@ method", NSStringFromSelector(_cmd)]
                                 userInfo:nil];
}

+ (NSString *)imageUTType {
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:[NSString stringWithFormat:@"For `TMSDImageIOAnimatedCoder` subclass, you must override %@ method", NSStringFromSelector(_cmd)]
                                 userInfo:nil];
}

+ (NSString *)dictionaryProperty {
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:[NSString stringWithFormat:@"For `TMSDImageIOAnimatedCoder` subclass, you must override %@ method", NSStringFromSelector(_cmd)]
                                 userInfo:nil];
}

+ (NSString *)unclampedDelayTimeProperty {
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:[NSString stringWithFormat:@"For `TMSDImageIOAnimatedCoder` subclass, you must override %@ method", NSStringFromSelector(_cmd)]
                                 userInfo:nil];
}

+ (NSString *)delayTimeProperty {
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:[NSString stringWithFormat:@"For `TMSDImageIOAnimatedCoder` subclass, you must override %@ method", NSStringFromSelector(_cmd)]
                                 userInfo:nil];
}

+ (NSString *)loopCountProperty {
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:[NSString stringWithFormat:@"For `TMSDImageIOAnimatedCoder` subclass, you must override %@ method", NSStringFromSelector(_cmd)]
                                 userInfo:nil];
}

+ (NSUInteger)defaultLoopCount {
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:[NSString stringWithFormat:@"For `TMSDImageIOAnimatedCoder` subclass, you must override %@ method", NSStringFromSelector(_cmd)]
                                 userInfo:nil];
}

#pragma mark - Utils

+ (BOOL)canDecodeFromFormat:(TMSDImageFormat)format {
    static dispatch_once_t onceToken;
    static NSSet *imageUTTypeSet;
    dispatch_once(&onceToken, ^{
        NSArray *imageUTTypes = (__bridge_transfer NSArray *)CGImageSourceCopyTypeIdentifiers();
        imageUTTypeSet = [NSSet setWithArray:imageUTTypes];
    });
    CFStringRef imageUTType = [NSData tmsd_UTTypeFromImageFormat:format];
    if ([imageUTTypeSet containsObject:(__bridge NSString *)(imageUTType)]) {
        // Can decode from target format
        return YES;
    }
    return NO;
}

+ (BOOL)canEncodeToFormat:(TMSDImageFormat)format {
    static dispatch_once_t onceToken;
    static NSSet *imageUTTypeSet;
    dispatch_once(&onceToken, ^{
        NSArray *imageUTTypes = (__bridge_transfer NSArray *)CGImageDestinationCopyTypeIdentifiers();
        imageUTTypeSet = [NSSet setWithArray:imageUTTypes];
    });
    CFStringRef imageUTType = [NSData tmsd_UTTypeFromImageFormat:format];
    if ([imageUTTypeSet containsObject:(__bridge NSString *)(imageUTType)]) {
        // Can encode to target format
        return YES;
    }
    return NO;
}

+ (NSUInteger)imageLoopCountWithSource:(CGImageSourceRef)source {
    NSUInteger loopCount = self.defaultLoopCount;
    NSDictionary *imageProperties = (__bridge_transfer NSDictionary *)CGImageSourceCopyProperties(source, NULL);
    NSDictionary *containerProperties = imageProperties[self.dictionaryProperty];
    if (containerProperties) {
        NSNumber *containerLoopCount = containerProperties[self.loopCountProperty];
        if (containerLoopCount != nil) {
            loopCount = containerLoopCount.unsignedIntegerValue;
        }
    }
    return loopCount;
}

+ (NSTimeInterval)frameDurationAtIndex:(NSUInteger)index source:(CGImageSourceRef)source {
    NSDictionary *options = @{
        (__bridge NSString *)kCGImageSourceShouldCacheImmediately : @(YES),
        (__bridge NSString *)kCGImageSourceShouldCache : @(YES) // Always cache to reduce CPU usage
    };
    NSTimeInterval frameDuration = 0.1;
    CFDictionaryRef cfFrameProperties = CGImageSourceCopyPropertiesAtIndex(source, index, (__bridge CFDictionaryRef)options);
    if (!cfFrameProperties) {
        return frameDuration;
    }
    NSDictionary *frameProperties = (__bridge NSDictionary *)cfFrameProperties;
    NSDictionary *containerProperties = frameProperties[self.dictionaryProperty];
    
    NSNumber *delayTimeUnclampedProp = containerProperties[self.unclampedDelayTimeProperty];
    if (delayTimeUnclampedProp != nil) {
        frameDuration = [delayTimeUnclampedProp doubleValue];
    } else {
        NSNumber *delayTimeProp = containerProperties[self.delayTimeProperty];
        if (delayTimeProp != nil) {
            frameDuration = [delayTimeProp doubleValue];
        }
    }
    
    // Many annoying ads specify a 0 duration to make an image flash as quickly as possible.
    // We follow Firefox's behavior and use a duration of 100 ms for any frames that specify
    // a duration of <= 10 ms. See <rdar://problem/7689300> and <http://webkit.org/b/36082>
    // for more information.
    
    if (frameDuration < 0.011) {
        frameDuration = 0.1;
    }
    
    CFRelease(cfFrameProperties);
    return frameDuration;
}

+ (UIImage *)createFrameAtIndex:(NSUInteger)index source:(CGImageSourceRef)source scale:(CGFloat)scale preserveAspectRatio:(BOOL)preserveAspectRatio thumbnailSize:(CGSize)thumbnailSize options:(NSDictionary *)options {
    // Some options need to pass to `CGImageSourceCopyPropertiesAtIndex` before `CGImageSourceCreateImageAtIndex`, or ImageIO will ignore them because they parse once :)
    // Parse the image properties
    NSDictionary *properties = (__bridge_transfer NSDictionary *)CGImageSourceCopyPropertiesAtIndex(source, index, (__bridge CFDictionaryRef)options);
    CGFloat pixelWidth = [properties[(__bridge NSString *)kCGImagePropertyPixelWidth] doubleValue];
    CGFloat pixelHeight = [properties[(__bridge NSString *)kCGImagePropertyPixelHeight] doubleValue];
    CGImagePropertyOrientation exifOrientation = (CGImagePropertyOrientation)[properties[(__bridge NSString *)kCGImagePropertyOrientation] unsignedIntegerValue];
    if (!exifOrientation) {
        exifOrientation = kCGImagePropertyOrientationUp;
    }

    NSMutableDictionary *decodingOptions;
    if (options) {
        decodingOptions = [NSMutableDictionary dictionaryWithDictionary:options];
    } else {
        decodingOptions = [NSMutableDictionary dictionary];
    }
    CGImageRef imageRef;
    BOOL createFullImage = thumbnailSize.width == 0 || thumbnailSize.height == 0 || pixelWidth == 0 || pixelHeight == 0 || (pixelWidth <= thumbnailSize.width && pixelHeight <= thumbnailSize.height);
    if (createFullImage) {
        imageRef = CGImageSourceCreateImageAtIndex(source, index, (__bridge CFDictionaryRef)[decodingOptions copy]);
    } else {
        decodingOptions[(__bridge NSString *)kCGImageSourceCreateThumbnailWithTransform] = @(preserveAspectRatio);
        CGFloat maxPixelSize;
        if (preserveAspectRatio) {
            CGFloat pixelRatio = pixelWidth / pixelHeight;
            CGFloat thumbnailRatio = thumbnailSize.width / thumbnailSize.height;
            if (pixelRatio > thumbnailRatio) {
                maxPixelSize = MAX(thumbnailSize.width, thumbnailSize.width / pixelRatio);
            } else {
                maxPixelSize = MAX(thumbnailSize.height, thumbnailSize.height * pixelRatio);
            }
        } else {
            maxPixelSize = MAX(thumbnailSize.width, thumbnailSize.height);
        }
        decodingOptions[(__bridge NSString *)kCGImageSourceThumbnailMaxPixelSize] = @(maxPixelSize);
        decodingOptions[(__bridge NSString *)kCGImageSourceCreateThumbnailFromImageAlways] = @(YES);
        imageRef = CGImageSourceCreateThumbnailAtIndex(source, index, (__bridge CFDictionaryRef)[decodingOptions copy]);
    }
    if (!imageRef) {
        return nil;
    }
    // Thumbnail image post-process
    if (!createFullImage) {
        if (preserveAspectRatio) {
            // kCGImageSourceCreateThumbnailWithTransform will apply EXIF transform as well, we should not apply twice
            exifOrientation = kCGImagePropertyOrientationUp;
        } else {
            // `CGImageSourceCreateThumbnailAtIndex` take only pixel dimension, if not `preserveAspectRatio`, we should manual scale to the target size
            CGImageRef scaledImageRef = [TMSDImageCoderHelper CGImageCreateScaled:imageRef size:thumbnailSize];
            CGImageRelease(imageRef);
            imageRef = scaledImageRef;
        }
    }
    
#if TMSD_UIKIT || TMSD_WATCH
    UIImageOrientation imageOrientation = [TMSDImageCoderHelper imageOrientationFromEXIFOrientation:exifOrientation];
    UIImage *image = [[UIImage alloc] initWithCGImage:imageRef scale:scale orientation:imageOrientation];
#else
    UIImage *image = [[UIImage alloc] initWithCGImage:imageRef scale:scale orientation:exifOrientation];
#endif
    CGImageRelease(imageRef);
    return image;
}

#pragma mark - Decode
- (BOOL)canDecodeFromData:(nullable NSData *)data {
    return ([NSData tmsd_imageFormatForImageData:data] == self.class.imageFormat);
}

- (UIImage *)decodedImageWithData:(NSData *)data options:(nullable TMSDImageCoderOptions *)options {
    if (!data) {
        return nil;
    }
    CGFloat scale = 1;
    NSNumber *scaleFactor = options[TMSDImageCoderDecodeScaleFactor];
    if (scaleFactor != nil) {
        scale = MAX([scaleFactor doubleValue], 1);
    }
    
    CGSize thumbnailSize = CGSizeZero;
    NSValue *thumbnailSizeValue = options[TMSDImageCoderDecodeThumbnailPixelSize];
    if (thumbnailSizeValue != nil) {
#if TMSD_MAC
        thumbnailSize = thumbnailSizeValue.sizeValue;
#else
        thumbnailSize = thumbnailSizeValue.CGSizeValue;
#endif
    }
    
    BOOL preserveAspectRatio = YES;
    NSNumber *preserveAspectRatioValue = options[TMSDImageCoderDecodePreserveAspectRatio];
    if (preserveAspectRatioValue != nil) {
        preserveAspectRatio = preserveAspectRatioValue.boolValue;
    }
    
#if TMSD_MAC
    // If don't use thumbnail, prefers the built-in generation of frames (GIF/APNG)
    // Which decode frames in time and reduce memory usage
    if (thumbnailSize.width == 0 || thumbnailSize.height == 0) {
        TMSDAnimatedImageRep *imageRep = [[TMSDAnimatedImageRep alloc] initWithData:data];
        if (imageRep) {
            NSSize size = NSMakeSize(imageRep.pixelsWide / scale, imageRep.pixelsHigh / scale);
            imageRep.size = size;
            NSImage *animatedImage = [[NSImage alloc] initWithSize:size];
            [animatedImage addRepresentation:imageRep];
            animatedImage.tmsd_imageFormat = self.class.imageFormat;
            return animatedImage;
        }
    }
#endif
    
    CGImageSourceRef source = CGImageSourceCreateWithData((__bridge CFDataRef)data, NULL);
    if (!source) {
        return nil;
    }
    size_t count = CGImageSourceGetCount(source);
    UIImage *animatedImage;
    
    BOOL decodeFirstFrame = [options[TMSDImageCoderDecodeFirstFrameOnly] boolValue];
    if (decodeFirstFrame || count <= 1) {
        animatedImage = [self.class createFrameAtIndex:0 source:source scale:scale preserveAspectRatio:preserveAspectRatio thumbnailSize:thumbnailSize options:nil];
    } else {
        NSMutableArray<TMSDImageFrame *> *frames = [NSMutableArray array];
        
        for (size_t i = 0; i < count; i++) {
            UIImage *image = [self.class createFrameAtIndex:i source:source scale:scale preserveAspectRatio:preserveAspectRatio thumbnailSize:thumbnailSize options:nil];
            if (!image) {
                continue;
            }
            
            NSTimeInterval duration = [self.class frameDurationAtIndex:i source:source];
            
            TMSDImageFrame *frame = [TMSDImageFrame frameWithImage:image duration:duration];
            [frames addObject:frame];
        }
        
        NSUInteger loopCount = [self.class imageLoopCountWithSource:source];
        
        animatedImage = [TMSDImageCoderHelper animatedImageWithFrames:frames];
        animatedImage.tmsd_imageLoopCount = loopCount;
    }
    animatedImage.tmsd_imageFormat = self.class.imageFormat;
    CFRelease(source);
    
    return animatedImage;
}

#pragma mark - Progressive Decode

- (BOOL)canIncrementalDecodeFromData:(NSData *)data {
    return ([NSData tmsd_imageFormatForImageData:data] == self.class.imageFormat);
}

- (instancetype)initIncrementalWithOptions:(nullable TMSDImageCoderOptions *)options {
    self = [super init];
    if (self) {
        NSString *imageUTType = self.class.imageUTType;
        _imageSource = CGImageSourceCreateIncremental((__bridge CFDictionaryRef)@{(__bridge NSString *)kCGImageSourceTypeIdentifierHint : imageUTType});
        CGFloat scale = 1;
        NSNumber *scaleFactor = options[TMSDImageCoderDecodeScaleFactor];
        if (scaleFactor != nil) {
            scale = MAX([scaleFactor doubleValue], 1);
        }
        _scale = scale;
        CGSize thumbnailSize = CGSizeZero;
        NSValue *thumbnailSizeValue = options[TMSDImageCoderDecodeThumbnailPixelSize];
        if (thumbnailSizeValue != nil) {
    #if TMSD_MAC
            thumbnailSize = thumbnailSizeValue.sizeValue;
    #else
            thumbnailSize = thumbnailSizeValue.CGSizeValue;
    #endif
        }
        _thumbnailSize = thumbnailSize;
        BOOL preserveAspectRatio = YES;
        NSNumber *preserveAspectRatioValue = options[TMSDImageCoderDecodePreserveAspectRatio];
        if (preserveAspectRatioValue != nil) {
            preserveAspectRatio = preserveAspectRatioValue.boolValue;
        }
        _preserveAspectRatio = preserveAspectRatio;
#if TMSD_UIKIT
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceiveMemoryWarning:) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
#endif
    }
    return self;
}

- (void)updateIncrementalData:(NSData *)data finished:(BOOL)finished {
    if (_finished) {
        return;
    }
    _imageData = data;
    _finished = finished;
    
    // The following code is from http://www.cocoaintheshell.com/2011/05/progressive-images-download-imageio/
    // Thanks to the author @Nyx0uf
    
    // Update the data source, we must pass ALL the data, not just the new bytes
    CGImageSourceUpdateData(_imageSource, (__bridge CFDataRef)data, finished);
    
    if (_width + _height == 0) {
        NSDictionary *options = @{
            (__bridge NSString *)kCGImageSourceShouldCacheImmediately : @(YES),
            (__bridge NSString *)kCGImageSourceShouldCache : @(YES) // Always cache to reduce CPU usage
        };
        CFDictionaryRef properties = CGImageSourceCopyPropertiesAtIndex(_imageSource, 0, (__bridge CFDictionaryRef)options);
        if (properties) {
            CFTypeRef val = CFDictionaryGetValue(properties, kCGImagePropertyPixelHeight);
            if (val) CFNumberGetValue(val, kCFNumberLongType, &_height);
            val = CFDictionaryGetValue(properties, kCGImagePropertyPixelWidth);
            if (val) CFNumberGetValue(val, kCFNumberLongType, &_width);
            CFRelease(properties);
        }
    }
    
    // For animated image progressive decoding because the frame count and duration may be changed.
    [self scanAndCheckFramesValidWithImageSource:_imageSource];
}

- (UIImage *)incrementalDecodedImageWithOptions:(TMSDImageCoderOptions *)options {
    UIImage *image;
    
    if (_width + _height > 0) {
        // Create the image
        CGFloat scale = _scale;
        NSNumber *scaleFactor = options[TMSDImageCoderDecodeScaleFactor];
        if (scaleFactor != nil) {
            scale = MAX([scaleFactor doubleValue], 1);
        }
        image = [self.class createFrameAtIndex:0 source:_imageSource scale:scale preserveAspectRatio:_preserveAspectRatio thumbnailSize:_thumbnailSize options:nil];
        if (image) {
            image.tmsd_imageFormat = self.class.imageFormat;
        }
    }
    
    return image;
}

#pragma mark - Encode
- (BOOL)canEncodeToFormat:(TMSDImageFormat)format {
    return (format == self.class.imageFormat);
}

- (NSData *)encodedDataWithImage:(UIImage *)image format:(TMSDImageFormat)format options:(nullable TMSDImageCoderOptions *)options {
    if (!image) {
        return nil;
    }
    CGImageRef imageRef = image.CGImage;
    if (!imageRef) {
        // Earily return, supports CGImage only
        return nil;
    }
    
    if (format != self.class.imageFormat) {
        return nil;
    }
    
    NSMutableData *imageData = [NSMutableData data];
    CFStringRef imageUTType = [NSData tmsd_UTTypeFromImageFormat:format];
    NSArray<TMSDImageFrame *> *frames = [TMSDImageCoderHelper framesFromAnimatedImage:image];
    
    // Create an image destination. Animated Image does not support EXIF image orientation TODO
    // The `CGImageDestinationCreateWithData` will log a warning when count is 0, use 1 instead.
    CGImageDestinationRef imageDestination = CGImageDestinationCreateWithData((__bridge CFMutableDataRef)imageData, imageUTType, frames.count ?: 1, NULL);
    if (!imageDestination) {
        // Handle failure.
        return nil;
    }
    NSMutableDictionary *properties = [NSMutableDictionary dictionary];
    // Encoding Options
    double compressionQuality = 1;
    if (options[TMSDImageCoderEncodeCompressionQuality]) {
        compressionQuality = [options[TMSDImageCoderEncodeCompressionQuality] doubleValue];
    }
    properties[(__bridge NSString *)kCGImageDestinationLossyCompressionQuality] = @(compressionQuality);
    CGColorRef backgroundColor = [options[TMSDImageCoderEncodeBackgroundColor] CGColor];
    if (backgroundColor) {
        properties[(__bridge NSString *)kCGImageDestinationBackgroundColor] = (__bridge id)(backgroundColor);
    }
    CGSize maxPixelSize = CGSizeZero;
    NSValue *maxPixelSizeValue = options[TMSDImageCoderEncodeMaxPixelSize];
    if (maxPixelSizeValue != nil) {
#if TMSD_MAC
        maxPixelSize = maxPixelSizeValue.sizeValue;
#else
        maxPixelSize = maxPixelSizeValue.CGSizeValue;
#endif
    }
    CGFloat pixelWidth = (CGFloat)CGImageGetWidth(imageRef);
    CGFloat pixelHeight = (CGFloat)CGImageGetHeight(imageRef);
    CGFloat finalPixelSize = 0;
    BOOL encodeFullImage = maxPixelSize.width == 0 || maxPixelSize.height == 0 || pixelWidth == 0 || pixelHeight == 0 || (pixelWidth <= maxPixelSize.width && pixelHeight <= maxPixelSize.height);
    if (!encodeFullImage) {
        // Thumbnail Encoding
        CGFloat pixelRatio = pixelWidth / pixelHeight;
        CGFloat maxPixelSizeRatio = maxPixelSize.width / maxPixelSize.height;
        if (pixelRatio > maxPixelSizeRatio) {
            finalPixelSize = MAX(maxPixelSize.width, maxPixelSize.width / pixelRatio);
        } else {
            finalPixelSize = MAX(maxPixelSize.height, maxPixelSize.height * pixelRatio);
        }
        properties[(__bridge NSString *)kCGImageDestinationImageMaxPixelSize] = @(finalPixelSize);
    }
    NSUInteger maxFileSize = [options[TMSDImageCoderEncodeMaxFileSize] unsignedIntegerValue];
    if (maxFileSize > 0) {
        properties[kSDCGImageDestinationRequestedFileSize] = @(maxFileSize);
        // Remove the quality if we have file size limit
        properties[(__bridge NSString *)kCGImageDestinationLossyCompressionQuality] = nil;
    }
    BOOL embedThumbnail = NO;
    if (options[TMSDImageCoderEncodeEmbedThumbnail]) {
        embedThumbnail = [options[TMSDImageCoderEncodeEmbedThumbnail] boolValue];
    }
    properties[(__bridge NSString *)kCGImageDestinationEmbedThumbnail] = @(embedThumbnail);
    
    BOOL encodeFirstFrame = [options[TMSDImageCoderEncodeFirstFrameOnly] boolValue];
    if (encodeFirstFrame || frames.count == 0) {
        // for static single images
        CGImageDestinationAddImage(imageDestination, imageRef, (__bridge CFDictionaryRef)properties);
    } else {
        // for animated images
        NSUInteger loopCount = image.tmsd_imageLoopCount;
        NSDictionary *containerProperties = @{
            self.class.dictionaryProperty: @{self.class.loopCountProperty : @(loopCount)}
        };
        // container level properties (applies for `CGImageDestinationSetProperties`, not individual frames)
        CGImageDestinationSetProperties(imageDestination, (__bridge CFDictionaryRef)containerProperties);
        
        for (size_t i = 0; i < frames.count; i++) {
            TMSDImageFrame *frame = frames[i];
            NSTimeInterval frameDuration = frame.duration;
            CGImageRef frameImageRef = frame.image.CGImage;
            properties[self.class.dictionaryProperty] = @{self.class.delayTimeProperty : @(frameDuration)};
            CGImageDestinationAddImage(imageDestination, frameImageRef, (__bridge CFDictionaryRef)properties);
        }
    }
    // Finalize the destination.
    if (CGImageDestinationFinalize(imageDestination) == NO) {
        // Handle failure.
        imageData = nil;
    }
    
    CFRelease(imageDestination);
    
    return [imageData copy];
}

#pragma mark - TMSDAnimatedImageCoder
- (nullable instancetype)initWithAnimatedImageData:(nullable NSData *)data options:(nullable TMSDImageCoderOptions *)options {
    if (!data) {
        return nil;
    }
    self = [super init];
    if (self) {
        CGImageSourceRef imageSource = CGImageSourceCreateWithData((__bridge CFDataRef)data, NULL);
        if (!imageSource) {
            return nil;
        }
        BOOL framesValid = [self scanAndCheckFramesValidWithImageSource:imageSource];
        if (!framesValid) {
            CFRelease(imageSource);
            return nil;
        }
        CGFloat scale = 1;
        NSNumber *scaleFactor = options[TMSDImageCoderDecodeScaleFactor];
        if (scaleFactor != nil) {
            scale = MAX([scaleFactor doubleValue], 1);
        }
        _scale = scale;
        CGSize thumbnailSize = CGSizeZero;
        NSValue *thumbnailSizeValue = options[TMSDImageCoderDecodeThumbnailPixelSize];
        if (thumbnailSizeValue != nil) {
    #if TMSD_MAC
            thumbnailSize = thumbnailSizeValue.sizeValue;
    #else
            thumbnailSize = thumbnailSizeValue.CGSizeValue;
    #endif
        }
        _thumbnailSize = thumbnailSize;
        BOOL preserveAspectRatio = YES;
        NSNumber *preserveAspectRatioValue = options[TMSDImageCoderDecodePreserveAspectRatio];
        if (preserveAspectRatioValue != nil) {
            preserveAspectRatio = preserveAspectRatioValue.boolValue;
        }
        _preserveAspectRatio = preserveAspectRatio;
        _imageSource = imageSource;
        _imageData = data;
#if TMSD_UIKIT
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceiveMemoryWarning:) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
#endif
    }
    return self;
}

- (BOOL)scanAndCheckFramesValidWithImageSource:(CGImageSourceRef)imageSource {
    if (!imageSource) {
        return NO;
    }
    NSUInteger frameCount = CGImageSourceGetCount(imageSource);
    NSUInteger loopCount = [self.class imageLoopCountWithSource:imageSource];
    NSMutableArray<TMSDImageIOCoderFrame *> *frames = [NSMutableArray array];
    
    for (size_t i = 0; i < frameCount; i++) {
        TMSDImageIOCoderFrame *frame = [[TMSDImageIOCoderFrame alloc] init];
        frame.index = i;
        frame.duration = [self.class frameDurationAtIndex:i source:imageSource];
        [frames addObject:frame];
    }
    
    _frameCount = frameCount;
    _loopCount = loopCount;
    _frames = [frames copy];
    
    return YES;
}

- (NSData *)animatedImageData {
    return _imageData;
}

- (NSUInteger)animatedImageLoopCount {
    return _loopCount;
}

- (NSUInteger)animatedImageFrameCount {
    return _frameCount;
}

- (NSTimeInterval)animatedImageDurationAtIndex:(NSUInteger)index {
    if (index >= _frameCount) {
        return 0;
    }
    return _frames[index].duration;
}

- (UIImage *)animatedImageFrameAtIndex:(NSUInteger)index {
    if (index >= _frameCount) {
        return nil;
    }
    // Animated Image should not use the CGContext solution to force decode. Prefers to use Image/IO built in method, which is safer and memory friendly, see https://github.com/TMSDWebImage/TMSDWebImage/issues/2961
    NSDictionary *options = @{
        (__bridge NSString *)kCGImageSourceShouldCacheImmediately : @(YES),
        (__bridge NSString *)kCGImageSourceShouldCache : @(YES) // Always cache to reduce CPU usage
    };
    UIImage *image = [self.class createFrameAtIndex:index source:_imageSource scale:_scale preserveAspectRatio:_preserveAspectRatio thumbnailSize:_thumbnailSize options:options];
    if (!image) {
        return nil;
    }
    image.tmsd_imageFormat = self.class.imageFormat;
    image.tmsd_isDecoded = YES;
    return image;
}

@end

