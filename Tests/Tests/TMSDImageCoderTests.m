/*
 * This file is part of the TMSDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 * (c) Matt Galloway
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import <TMSDWebImage/TMSDTestCase.h>
#import <TMSDWebImage/UIColor+TMSDHexString.h>
#import <TMSDWebImageWebPCoder/TMSDWebImageWebPCoder.h>

@interface TMSDImageIOCoder ()

+ (CGRect)boxRectFromPDFFData:(nonnull NSData *)data;

@end

@interface TMSDWebImageDecoderTests : TMSDTestCase

@end

@implementation TMSDWebImageDecoderTests

- (void)test01ThatDecodedImageWithNilImageReturnsNil {
    expect([UIImage tmsd_decodedImageWithImage:nil]).to.beNil();
    expect([UIImage tmsd_decodedAndScaledDownImageWithImage:nil]).to.beNil();
}

- (void)test02ThatDecodedImageWithImageWorksWithARegularJPGImage {
    NSString *testImagePath = [[NSBundle bundleForClass:[self class]] pathForResource:@"TestImage" ofType:@"jpg"];
    UIImage *image = [[UIImage alloc] initWithContentsOfFile:testImagePath];
    UIImage *decodedImage = [UIImage tmsd_decodedImageWithImage:image];
    expect(decodedImage).toNot.beNil();
    expect(decodedImage).toNot.equal(image);
    expect(decodedImage.size.width).to.equal(image.size.width);
    expect(decodedImage.size.height).to.equal(image.size.height);
}

- (void)test03ThatDecodedImageWithImageDoesNotDecodeAnimatedImages {
    NSString *testImagePath = [[NSBundle bundleForClass:[self class]] pathForResource:@"TestImage" ofType:@"gif"];
    UIImage *image = [[UIImage alloc] initWithContentsOfFile:testImagePath];
#if TMSD_MAC
    UIImage *animatedImage = image;
#else
    UIImage *animatedImage = [UIImage animatedImageWithImages:@[image] duration:0];
#endif
    UIImage *decodedImage = [UIImage tmsd_decodedImageWithImage:animatedImage];
    expect(decodedImage).toNot.beNil();
    expect(decodedImage).to.equal(animatedImage);
}

- (void)test04ThatDecodedImageWithImageWorksWithAlphaImages {
    NSString *testImagePath = [[NSBundle bundleForClass:[self class]] pathForResource:@"TestImage" ofType:@"png"];
    UIImage *image = [[UIImage alloc] initWithContentsOfFile:testImagePath];
    UIImage *decodedImage = [UIImage tmsd_decodedImageWithImage:image];
    expect(decodedImage).toNot.beNil();
    expect(decodedImage).toNot.equal(image);
}

- (void)test05ThatDecodedImageWithImageWorksEvenWithMonochromeImage {
    NSString *testImagePath = [[NSBundle bundleForClass:[self class]] pathForResource:@"MonochromeTestImage" ofType:@"jpg"];
    UIImage *image = [[UIImage alloc] initWithContentsOfFile:testImagePath];
    UIImage *decodedImage = [UIImage tmsd_decodedImageWithImage:image];
    expect(decodedImage).toNot.beNil();
    expect(decodedImage).toNot.equal(image);
    expect(decodedImage.size.width).to.equal(image.size.width);
    expect(decodedImage.size.height).to.equal(image.size.height);
}

- (void)test06ThatDecodeAndScaleDownImageWorks {
    NSString *testImagePath = [[NSBundle bundleForClass:[self class]] pathForResource:@"TestImageLarge" ofType:@"jpg"];
    UIImage *image = [[UIImage alloc] initWithContentsOfFile:testImagePath];
    UIImage *decodedImage = [UIImage tmsd_decodedAndScaledDownImageWithImage:image limitBytes:(60 * 1024 * 1024)];
    expect(decodedImage).toNot.beNil();
    expect(decodedImage).toNot.equal(image);
    expect(decodedImage.size.width).toNot.equal(image.size.width);
    expect(decodedImage.size.height).toNot.equal(image.size.height);
    expect(decodedImage.size.width * decodedImage.size.height).to.beLessThanOrEqualTo(60 * 1024 * 1024 / 4);    // how many pixels in 60 megs
}

- (void)test07ThatDecodeAndScaleDownImageDoesNotScaleSmallerImage {
    // check when user use the larget bytes than image pixels byets, we do not scale up the image (defaults 60MB means 3965x3965 pixels)
    NSString *testImagePath = [[NSBundle bundleForClass:[self class]] pathForResource:@"TestImage" ofType:@"jpg"];
    UIImage *image = [[UIImage alloc] initWithContentsOfFile:testImagePath];
    UIImage *decodedImage = [UIImage tmsd_decodedAndScaledDownImageWithImage:image];
    expect(decodedImage).toNot.beNil();
    expect(decodedImage).toNot.equal(image);
    expect(decodedImage.size.width).to.equal(image.size.width);
    expect(decodedImage.size.height).to.equal(image.size.height);
}

- (void)test07ThatDecodeAndScaleDownImageScaleSmallerBytes {
    // Check when user provide too small bytes, we scale it down to 1x1, but not return the force decoded original size image
    NSString *testImagePath = [[NSBundle bundleForClass:[self class]] pathForResource:@"TestImage" ofType:@"jpg"];
    UIImage *image = [[UIImage alloc] initWithContentsOfFile:testImagePath];
    UIImage *decodedImage = [UIImage tmsd_decodedAndScaledDownImageWithImage:image limitBytes:1];
    expect(decodedImage).toNot.beNil();
    expect(decodedImage).toNot.equal(image);
    expect(decodedImage.size.width).to.equal(1);
    expect(decodedImage.size.height).to.equal(1);
}

- (void)test07ThatDecodeAndScaleDownAlwaysCompleteRendering {
    // Check that when the height of the image used is not evenly divisible by the height of the tile, the output image can also be rendered completely.
    
    UIColor *imageColor = UIColor.blackColor;
    CGSize imageSize = CGSizeMake(3024, 4032);
    CGRect imageRect = CGRectMake(0, 0, imageSize.width, imageSize.height);
    TMSDGraphicsImageRendererFormat *format = [[TMSDGraphicsImageRendererFormat alloc] init];
    format.scale = 1;
    TMSDGraphicsImageRenderer *renderer = [[TMSDGraphicsImageRenderer alloc] initWithSize:imageSize format:format];
    UIImage *image = [renderer imageWithActions:^(CGContextRef  _Nonnull context) {
        CGContextSetFillColorWithColor(context, [imageColor CGColor]);
        CGContextFillRect(context, imageRect);
    }];
    
    UIImage *decodedImage = [UIImage tmsd_decodedAndScaledDownImageWithImage:image limitBytes:20 * 1024 * 1024];
    UIColor *testColor = [decodedImage tmsd_colorAtPoint:CGPointMake(0, decodedImage.size.height - 1)];
    expect(testColor.tmsd_hexString).equal(imageColor.tmsd_hexString);
}

- (void)test08ThatEncodeAlphaImageToJPGWithBackgroundColor {
    NSString *testImagePath = [[NSBundle bundleForClass:[self class]] pathForResource:@"TestImage" ofType:@"png"];
    UIImage *image = [[UIImage alloc] initWithContentsOfFile:testImagePath];
    UIColor *backgroundColor = [UIColor blackColor];
    NSData *encodedData = [TMSDImageCodersManager.sharedManager encodedDataWithImage:image format:TMSDImageFormatJPEG options:@{TMSDImageCoderEncodeBackgroundColor : backgroundColor}];
    expect(encodedData).notTo.beNil();
    UIImage *decodedImage = [TMSDImageCodersManager.sharedManager decodedImageWithData:encodedData options:nil];
    expect(decodedImage).notTo.beNil();
    expect(decodedImage.size.width).to.equal(image.size.width);
    expect(decodedImage.size.height).to.equal(image.size.height);
    // Check background color, should not be white but the black color
    UIColor *testColor = [decodedImage tmsd_colorAtPoint:CGPointMake(1, 1)];
    expect(testColor.tmsd_hexString).equal(backgroundColor.tmsd_hexString);
}

- (void)test09ThatJPGImageEncodeWithMaxFileSize {
    NSString *testImagePath = [[NSBundle bundleForClass:[self class]] pathForResource:@"TestImageLarge" ofType:@"jpg"];
    UIImage *image = [[UIImage alloc] initWithContentsOfFile:testImagePath];
    // This large JPEG encoding size between (770KB ~ 2.23MB)
    NSUInteger limitFileSize = 1 * 1024 * 1024; // 1MB
    // 100 quality (biggest)
    NSData *maxEncodedData = [TMSDImageCodersManager.sharedManager encodedDataWithImage:image format:TMSDImageFormatJPEG options:nil];
    expect(maxEncodedData).notTo.beNil();
    expect(maxEncodedData.length).beGreaterThan(limitFileSize);
    // 0 quality (smallest)
    NSData *minEncodedData = [TMSDImageCodersManager.sharedManager encodedDataWithImage:image format:TMSDImageFormatJPEG options:@{TMSDImageCoderEncodeCompressionQuality : @(0)}];
    expect(minEncodedData).notTo.beNil();
    expect(minEncodedData.length).beLessThan(limitFileSize);
    NSData *limitEncodedData = [TMSDImageCodersManager.sharedManager encodedDataWithImage:image format:TMSDImageFormatJPEG options:@{TMSDImageCoderEncodeMaxFileSize : @(limitFileSize)}];
    expect(limitEncodedData).notTo.beNil();
    // So, if we limit the file size, the output data should in (770KB ~ 2.23MB)
    expect(limitEncodedData.length).beLessThan(maxEncodedData.length);
    expect(limitEncodedData.length).beGreaterThan(minEncodedData.length);
}

- (void)test10ThatAnimatedImageCacheImmediatelyWorks {
    NSString *testImagePath = [[NSBundle bundleForClass:[self class]] pathForResource:@"TestImageLarge" ofType:@"png"];
    NSData *testImageData = [NSData dataWithContentsOfFile:testImagePath];
    
    // Check that animated image rendering should not use lazy decoding (performance related)
    CFAbsoluteTime begin = CFAbsoluteTimeGetCurrent();
    TMSDImageAPNGCoder *coder = [[TMSDImageAPNGCoder alloc] initWithAnimatedImageData:testImageData options:@{TMSDImageCoderDecodeFirstFrameOnly : @(NO)}];
    UIImage *imageWithoutLazyDecoding = [coder animatedImageFrameAtIndex:0];
    CFAbsoluteTime end = CFAbsoluteTimeGetCurrent();
    CFAbsoluteTime duration = end - begin;
    expect(imageWithoutLazyDecoding.tmsd_isDecoded).beTruthy();
    
    // Check that static image rendering should use lazy decoding
    CFAbsoluteTime begin2 = CFAbsoluteTimeGetCurrent();
    TMSDImageAPNGCoder *coder2 = TMSDImageAPNGCoder.sharedCoder;
    UIImage *imageWithLazyDecoding = [coder2 decodedImageWithData:testImageData options:@{TMSDImageCoderDecodeFirstFrameOnly : @(YES)}];
    CFAbsoluteTime end2 = CFAbsoluteTimeGetCurrent();
    CFAbsoluteTime duration2 = end2 - begin2;
    expect(imageWithLazyDecoding.tmsd_isDecoded).beFalsy();
    
    // lazy decoding need less time (10x)
    expect(duration2 * 10.0).beLessThan(duration);
}

- (void)test11ThatAPNGPCoderWorks {
    NSURL *APNGURL = [[NSBundle bundleForClass:[self class]] URLForResource:@"TestImageAnimated" withExtension:@"apng"];
    [self verifyCoder:[TMSDImageAPNGCoder sharedCoder]
    withLocalImageURL:APNGURL
     supportsEncoding:YES
      isAnimatedImage:YES];
}

- (void)test12ThatGIFCoderWorks {
    NSURL *gifURL = [[NSBundle bundleForClass:[self class]] URLForResource:@"TestImage" withExtension:@"gif"];
    [self verifyCoder:[TMSDImageGIFCoder sharedCoder]
    withLocalImageURL:gifURL
     supportsEncoding:YES
      isAnimatedImage:YES];
}

- (void)test12ThatGIFWithoutLoopCountPlayOnce {
    // When GIF metadata does not contains any loop count information (`kCGImagePropertyGIFLoopCount`'s value nil)
    // The standard says it should just play once. See: http://www6.uniovi.es/gifanim/gifabout.htm
    // This behavior is different from other modern animated image format like APNG/WebP. Which will play infinitely
    NSString *testImagePath = [[NSBundle bundleForClass:[self class]] pathForResource:@"TestLoopCount" ofType:@"gif"];
    NSData *testImageData = [NSData dataWithContentsOfFile:testImagePath];
    UIImage *image = [TMSDImageGIFCoder.sharedCoder decodedImageWithData:testImageData options:nil];
    expect(image.tmsd_imageLoopCount).equal(1);
}

- (void)test13ThatHEICWorks {
    if (@available(iOS 11, tvOS 11, macOS 10.13, *)) {
        NSURL *heicURL = [[NSBundle bundleForClass:[self class]] URLForResource:@"TestImage" withExtension:@"heic"];
#if TMSD_UIKIT
        BOOL supportsEncoding = YES; // iPhone Simulator after Xcode 9.3 support HEIC encoding
#else
        BOOL supportsEncoding = NO; // Travis-CI Mac env currently does not support HEIC encoding
#endif
        [self verifyCoder:[TMSDImageIOCoder sharedCoder]
        withLocalImageURL:heicURL
         supportsEncoding:supportsEncoding
          isAnimatedImage:NO];
    }
}

- (void)test14ThatHEIFWorks {
    if (@available(iOS 11, tvOS 11, macOS 10.13, *)) {
        NSURL *heifURL = [[NSBundle bundleForClass:[self class]] URLForResource:@"TestImage" withExtension:@"heif"];
        [self verifyCoder:[TMSDImageIOCoder sharedCoder]
        withLocalImageURL:heifURL
         supportsEncoding:NO
          isAnimatedImage:NO];
    }
}

- (void)test15ThatCodersManagerWorks {
    TMSDImageCodersManager *manager = [[TMSDImageCodersManager alloc] init];
    manager.coders = @[TMSDImageIOCoder.sharedCoder];
    expect([manager canDecodeFromData:nil]).beTruthy(); // Image/IO will return YES for future format
    expect([manager decodedImageWithData:nil options:nil]).beNil();
    expect([manager canEncodeToFormat:TMSDImageFormatUndefined]).beTruthy(); // Image/IO will return YES for future format
    expect([manager encodedDataWithImage:nil format:TMSDImageFormatUndefined options:nil]).beNil();
}

- (void)test16ThatHEICAnimatedWorks {
    if (@available(iOS 13, tvOS 13, macOS 10.15, *)) {
        NSURL *heicURL = [[NSBundle bundleForClass:[self class]] URLForResource:@"TestImageAnimated" withExtension:@"heic"];
#if TMSD_UIKIT
        BOOL isAnimatedImage = YES;
        BOOL supportsEncoding = YES; // iPhone Simulator after Xcode 9.3 support HEIC encoding
#else
        BOOL isAnimatedImage = NO; // Travis-CI Mac env does not upgrade to macOS 10.15
        BOOL supportsEncoding = NO; // Travis-CI Mac env currently does not support HEIC encoding
#endif
        [self verifyCoder:[TMSDImageHEICCoder sharedCoder]
        withLocalImageURL:heicURL
         supportsEncoding:supportsEncoding
           encodingFormat:TMSDImageFormatHEIC
          isAnimatedImage:isAnimatedImage
            isVectorImage:NO];
    }
}

- (void)test17ThatPDFWorks {
    NSURL *pdfURL = [[NSBundle bundleForClass:[self class]] URLForResource:@"TestImage" withExtension:@"pdf"];
    [self verifyCoder:[TMSDImageIOCoder sharedCoder]
    withLocalImageURL:pdfURL
     supportsEncoding:NO
       encodingFormat:TMSDImageFormatUndefined
      isAnimatedImage:NO
        isVectorImage:YES];
}

- (void)test18ThatStaticWebPWorks {
    if (@available(iOS 14, tvOS 14, macOS 11, *)) {
        NSURL *staticWebPURL = [[NSBundle bundleForClass:[self class]] URLForResource:@"TestImageStatic" withExtension:@"webp"];
#if TMSD_TV
        /// TV OS does not support ImageIO's webp.
        [self verifyCoder:[TMSDImageWebPCoder sharedCoder]
#else
        [self verifyCoder:[TMSDImageAWebPCoder sharedCoder]
#endif
        withLocalImageURL:staticWebPURL
         supportsEncoding:NO // Currently (iOS 14.0) seems no encoding support
           encodingFormat:TMSDImageFormatWebP
          isAnimatedImage:NO
            isVectorImage:NO];
    }
}

- (void)test19ThatAnimatedWebPWorks {
    if (@available(iOS 14, tvOS 14, macOS 11, *)) {
        NSURL *staticWebPURL = [[NSBundle bundleForClass:[self class]] URLForResource:@"TestImageAnimated" withExtension:@"webp"];
#if TMSD_TV
        /// TV OS does not support ImageIO's webp.
        [self verifyCoder:[TMSDImageWebPCoder sharedCoder]
#else
        [self verifyCoder:[TMSDImageAWebPCoder sharedCoder]
#endif
        withLocalImageURL:staticWebPURL
         supportsEncoding:NO // Currently (iOS 14.0) seems no encoding support
           encodingFormat:TMSDImageFormatWebP
          isAnimatedImage:YES
            isVectorImage:NO];
    }
}

- (void)test20ThatImageIOAnimatedCoderAbstractClass {
    TMSDImageIOAnimatedCoder *coder = [[TMSDImageIOAnimatedCoder alloc] init];
    @try {
        [coder canEncodeToFormat:TMSDImageFormatPNG];
        XCTFail("Should throw exception");
    } @catch (NSException *exception) {
        expect(exception);
    }
}

- (void)test21ThatEmbedThumbnailHEICWorks {
    if (@available(iOS 11, tvOS 11, macOS 10.13, *)) {
        // The input HEIC does not contains any embed thumbnail
        NSURL *heicURL = [[NSBundle bundleForClass:[self class]] URLForResource:@"TestImage" withExtension:@"heic"];
        CGImageSourceRef source = CGImageSourceCreateWithURL((__bridge CFURLRef)heicURL, nil);
        expect(source).notTo.beNil();
        NSArray *thumbnailImages = [self thumbnailImagesFromImageSource:source];
        expect(thumbnailImages.count).equal(0);
        
        CGImageRef imageRef = CGImageSourceCreateImageAtIndex(source, 0, nil);
#if TMSD_UIKIT
        UIImage *image = [[UIImage alloc] initWithCGImage:imageRef scale:1 orientation: UIImageOrientationUp];
#else
        UIImage *image = [[UIImage alloc] initWithCGImage:imageRef scale:1 orientation:kCGImagePropertyOrientationUp];
#endif
        CGImageRelease(imageRef);
        // Encode with embed thumbnail
        NSData *encodedData = [TMSDImageIOCoder.sharedCoder encodedDataWithImage:image format:TMSDImageFormatHEIC options:@{TMSDImageCoderEncodeEmbedThumbnail : @(YES)}];
        
        // The new HEIC contains one embed thumbnail
        CGImageSourceRef source2 = CGImageSourceCreateWithData((__bridge CFDataRef)encodedData, nil);
        expect(source2).notTo.beNil();
        NSArray *thumbnailImages2 = [self thumbnailImagesFromImageSource:source2];
        expect(thumbnailImages2.count).equal(1);
        
        // Currently ImageIO has no control to custom embed thumbnail pixel size, just check the behavior :)
        NSDictionary *thumbnailImageInfo = thumbnailImages2.firstObject;
        NSUInteger thumbnailWidth = [thumbnailImageInfo[(__bridge NSString *)kCGImagePropertyWidth] unsignedIntegerValue];
        NSUInteger thumbnailHeight = [thumbnailImageInfo[(__bridge NSString *)kCGImagePropertyHeight] unsignedIntegerValue];
        expect(thumbnailWidth).equal(320);
        expect(thumbnailHeight).equal(212);
    }
}

- (void)test22ThatThumbnailDecodeCalculation {
    NSString *testImagePath = [[NSBundle bundleForClass:[self class]] pathForResource:@"TestImageLarge" ofType:@"jpg"];
    NSData *testImageData = [NSData dataWithContentsOfFile:testImagePath];
    CGSize thumbnailSize = CGSizeMake(400, 300);
    UIImage *image = [TMSDImageIOCoder.sharedCoder decodedImageWithData:testImageData options:@{
        TMSDImageCoderDecodePreserveAspectRatio: @(YES),
        TMSDImageCoderDecodeThumbnailPixelSize: @(thumbnailSize)}];
    CGSize imageSize = image.size;
    expect(imageSize.width).equal(400);
    expect(imageSize.height).equal(263);
}

- (void)test23ThatThumbnailEncodeCalculation {
    NSString *testImagePath = [[NSBundle bundleForClass:[self class]] pathForResource:@"TestImageLarge" ofType:@"jpg"];
    NSData *testImageData = [NSData dataWithContentsOfFile:testImagePath];
    UIImage *image = [TMSDImageIOCoder.sharedCoder decodedImageWithData:testImageData options:nil];
    expect(image.size).equal(CGSizeMake(5250, 3450));
    CGSize thumbnailSize = CGSizeMake(4000, 4000); // 3450 < 4000 < 5250
    NSData *encodedData = [TMSDImageIOCoder.sharedCoder encodedDataWithImage:image format:TMSDImageFormatJPEG options:@{
            TMSDImageCoderEncodeMaxPixelSize: @(thumbnailSize)
    }];
    UIImage *encodedImage = [UIImage tmsd_imageWithData:encodedData];
    expect(encodedImage.size).equal(CGSizeMake(4000, 2629));
}

- (void)test24ThatScaleSizeCalculation {
    // preserveAspectRatio true
    CGSize size1 = [TMSDImageCoderHelper scaledSizeWithImageSize:CGSizeMake(100, 200) scaleSize:CGSizeMake(150, 150) preserveAspectRatio:YES shouldScaleUp:NO];
    expect(size1).equal(CGSizeMake(75, 150));
    CGSize size2 = [TMSDImageCoderHelper scaledSizeWithImageSize:CGSizeMake(100, 200) scaleSize:CGSizeMake(150, 150) preserveAspectRatio:YES shouldScaleUp:YES];
    expect(size2).equal(CGSizeMake(75, 150));
    CGSize size3 = [TMSDImageCoderHelper scaledSizeWithImageSize:CGSizeMake(100, 200) scaleSize:CGSizeMake(300, 300) preserveAspectRatio:YES shouldScaleUp:NO];
    expect(size3).equal(CGSizeMake(100, 200));
    CGSize size4 = [TMSDImageCoderHelper scaledSizeWithImageSize:CGSizeMake(100, 200) scaleSize:CGSizeMake(300, 300) preserveAspectRatio:YES shouldScaleUp:YES];
    expect(size4).equal(CGSizeMake(150, 300));
    
    // preserveAspectRatio false
    CGSize size5 = [TMSDImageCoderHelper scaledSizeWithImageSize:CGSizeMake(100, 200) scaleSize:CGSizeMake(150, 150) preserveAspectRatio:NO shouldScaleUp:NO];
    expect(size5).equal(CGSizeMake(100, 150));
    CGSize size6 = [TMSDImageCoderHelper scaledSizeWithImageSize:CGSizeMake(100, 200) scaleSize:CGSizeMake(150, 150) preserveAspectRatio:NO shouldScaleUp:YES];
    expect(size6).equal(CGSizeMake(150, 150));
    
    // 0 value
    CGSize size7 = [TMSDImageCoderHelper scaledSizeWithImageSize:CGSizeMake(0, 0) scaleSize:CGSizeMake(999, 999) preserveAspectRatio:NO shouldScaleUp:NO];
    expect(size7).equal(CGSizeMake(0, 0));
    CGSize size8 = [TMSDImageCoderHelper scaledSizeWithImageSize:CGSizeMake(999, 999) scaleSize:CGSizeMake(0, 0) preserveAspectRatio:NO shouldScaleUp:NO];
    expect(size8).equal(CGSizeMake(999, 999));
}

#pragma mark - Utils

- (void)verifyCoder:(id<TMSDImageCoder>)coder
withLocalImageURL:(NSURL *)imageUrl
 supportsEncoding:(BOOL)supportsEncoding
  isAnimatedImage:(BOOL)isAnimated {
    [self verifyCoder:coder withLocalImageURL:imageUrl supportsEncoding:supportsEncoding encodingFormat:TMSDImageFormatUndefined isAnimatedImage:isAnimated isVectorImage:NO];
}

- (void)verifyCoder:(id<TMSDImageCoder>)coder
  withLocalImageURL:(NSURL *)imageUrl
   supportsEncoding:(BOOL)supportsEncoding
     encodingFormat:(TMSDImageFormat)encodingFormat
    isAnimatedImage:(BOOL)isAnimated
      isVectorImage:(BOOL)isVector {
    NSData *inputImageData = [NSData dataWithContentsOfURL:imageUrl];
    expect(inputImageData).toNot.beNil();
    TMSDImageFormat inputImageFormat = [NSData tmsd_imageFormatForImageData:inputImageData];
    expect(inputImageFormat).toNot.equal(TMSDImageFormatUndefined);
    
    // 1 - check if we can decode - should be true
    expect([coder canDecodeFromData:inputImageData]).to.beTruthy();
    
    // 2 - decode from NSData to UIImage and check it
    UIImage *inputImage = [coder decodedImageWithData:inputImageData options:nil];
    expect(inputImage).toNot.beNil();
    
    if (isAnimated) {
        // 2a - check images count > 0 (only for animated images)
        expect(inputImage.tmsd_isAnimated).to.beTruthy();
        
        // 2b - check image size and scale for each frameImage (only for animated images)
#if TMSD_UIKIT
        CGSize imageSize = inputImage.size;
        CGFloat imageScale = inputImage.scale;
        [inputImage.images enumerateObjectsUsingBlock:^(UIImage * frameImage, NSUInteger idx, BOOL * stop) {
            expect(imageSize).to.equal(frameImage.size);
            expect(imageScale).to.equal(frameImage.scale);
        }];
#endif
    }
    
    // 3 - check thumbnail decoding
    CGFloat pixelWidth = inputImage.size.width;
    CGFloat pixelHeight = inputImage.size.height;
    expect(pixelWidth).beGreaterThan(0);
    expect(pixelHeight).beGreaterThan(0);
    // check vector format should use 72 DPI
    if (isVector) {
        CGRect boxRect = [TMSDImageIOCoder boxRectFromPDFFData:inputImageData];
        expect(boxRect.size.width).beGreaterThan(0);
        expect(boxRect.size.height).beGreaterThan(0);
        // Since 72 DPI is 1:1 from inch size to pixel size
        expect(boxRect.size.width).equal(pixelWidth);
        expect(boxRect.size.height).equal(pixelHeight);
    }
    
    // check thumbnail with scratch
    CGFloat thumbnailWidth = 50;
    CGFloat thumbnailHeight = 50;
    UIImage *thumbImage = [coder decodedImageWithData:inputImageData options:@{
        TMSDImageCoderDecodeThumbnailPixelSize : @(CGSizeMake(thumbnailWidth, thumbnailHeight)),
        TMSDImageCoderDecodePreserveAspectRatio : @(NO)
    }];
    expect(thumbImage).toNot.beNil();
    expect(thumbImage.size).equal(CGSizeMake(thumbnailWidth, thumbnailHeight));
    // check thumbnail with aspect ratio limit
    thumbImage = [coder decodedImageWithData:inputImageData options:@{
        TMSDImageCoderDecodeThumbnailPixelSize : @(CGSizeMake(thumbnailWidth, thumbnailHeight)),
        TMSDImageCoderDecodePreserveAspectRatio : @(YES)
    }];
    expect(thumbImage).toNot.beNil();
    CGFloat ratio = pixelWidth / pixelHeight;
    CGFloat thumbnailRatio = thumbnailWidth / thumbnailHeight;
    CGSize thumbnailPixelSize;
    if (ratio > thumbnailRatio) {
        thumbnailPixelSize = CGSizeMake(thumbnailWidth, round(thumbnailWidth / ratio));
    } else {
        thumbnailPixelSize = CGSizeMake(round(thumbnailHeight * ratio), thumbnailHeight);
    }
    // Image/IO's thumbnail API does not always use round to preserve precision, we check ABS <= 1
    expect(ABS(thumbImage.size.width - thumbnailPixelSize.width)).beLessThanOrEqualTo(1);
    expect(ABS(thumbImage.size.height - thumbnailPixelSize.height)).beLessThanOrEqualTo(1);
    
    
    if (supportsEncoding) {
        // 4 - check if we can encode to the original format
        if (encodingFormat == TMSDImageFormatUndefined) {
            encodingFormat = inputImageFormat;
        }
        expect([coder canEncodeToFormat:encodingFormat]).to.beTruthy();
        
        // 5 - encode from UIImage to NSData using the inputImageFormat and check it
        NSData *outputImageData = [coder encodedDataWithImage:inputImage format:encodingFormat options:nil];
        expect(outputImageData).toNot.beNil();
        UIImage *outputImage = [coder decodedImageWithData:outputImageData options:nil];
        expect(outputImage.size).to.equal(inputImage.size);
        expect(outputImage.scale).to.equal(inputImage.scale);
        expect(outputImage.tmsd_imageLoopCount).to.equal(inputImage.tmsd_imageLoopCount);
        
        // check max pixel size encoding with scratch
        CGFloat maxWidth = 50;
        CGFloat maxHeight = 50;
        CGFloat maxRatio = maxWidth / maxHeight;
        CGSize maxPixelSize;
        if (ratio > maxRatio) {
            maxPixelSize = CGSizeMake(maxWidth, round(maxWidth / ratio));
        } else {
            maxPixelSize = CGSizeMake(round(maxHeight * ratio), maxHeight);
        }
        NSData *outputMaxImageData = [coder encodedDataWithImage:inputImage format:encodingFormat options:@{TMSDImageCoderEncodeMaxPixelSize : @(CGSizeMake(maxWidth, maxHeight))}];
        UIImage *outputMaxImage = [coder decodedImageWithData:outputMaxImageData options:nil];
        // Image/IO's thumbnail API does not always use round to preserve precision, we check ABS <= 1
        expect(ABS(outputMaxImage.size.width - maxPixelSize.width)).beLessThanOrEqualTo(1);
        expect(ABS(outputMaxImage.size.height - maxPixelSize.height)).beLessThanOrEqualTo(1);
        expect(outputMaxImage.tmsd_imageLoopCount).to.equal(inputImage.tmsd_imageLoopCount);
    }
}

- (NSArray *)thumbnailImagesFromImageSource:(CGImageSourceRef)source API_AVAILABLE(ios(11.0), tvos(11.0), macos(10.13)) {
    NSDictionary *properties = (__bridge_transfer NSDictionary *)CGImageSourceCopyProperties(source, nil);
    NSDictionary *fileProperties = properties[(__bridge NSString *)kCGImagePropertyFileContentsDictionary];
    NSArray *imagesProperties = fileProperties[(__bridge NSString *)kCGImagePropertyImages];
    NSDictionary *imageProperties = imagesProperties.firstObject;
    NSArray *thumbnailImages = imageProperties[(__bridge NSString *)kCGImagePropertyThumbnailImages];
    
    return thumbnailImages;
}

@end
