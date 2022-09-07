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
#import <CoreImage/CoreImage.h>

@interface TMSDImageTransformerTests : TMSDTestCase

@property (nonatomic, strong) UIImage *testImageCG;
@property (nonatomic, strong) UIImage *testImageCI;

@end

@implementation TMSDImageTransformerTests

#pragma mark - UIImage+Transform

// UIImage+Transform test is hard to write because it's more about visual effect. Current it's tied to the `TestImage.png`, please keep that image or write new test with new image
- (void)test01UIImageTransformResizeCG {
    [self test01UIImageTransformResizeWithImage:self.testImageCG];
}

- (void)test01UIImageTransformResizeCI {
    [self test01UIImageTransformResizeWithImage:self.testImageCI];
}

- (void)test01UIImageTransformResizeWithImage:(UIImage *)testImage {
    CGSize scaleDownSize = CGSizeMake(200, 100);
    UIImage *scaledDownImage = [testImage tmsd_resizedImageWithSize:scaleDownSize scaleMode:TMSDImageScaleModeFill];
    expect(CGSizeEqualToSize(scaledDownImage.size, scaleDownSize)).beTruthy();
    CGSize scaleUpSize = CGSizeMake(2000, 1000);
    UIImage *scaledUpImage = [testImage tmsd_resizedImageWithSize:scaleUpSize scaleMode:TMSDImageScaleModeAspectFit];
    expect(CGSizeEqualToSize(scaledUpImage.size, scaleUpSize)).beTruthy();
    // Check image not inversion
    UIColor *topCenterColor = [scaledUpImage tmsd_colorAtPoint:CGPointMake(1000, 50)];
    expect([topCenterColor.tmsd_hexString isEqualToString:[UIColor blackColor].tmsd_hexString]).beTruthy();
}

- (void)test02UIImageTransformCropCG {
    [self test02UIImageTransformCropWithImage:self.testImageCG];
}

- (void)test02UIImageTransformCropCI {
    [self test02UIImageTransformCropWithImage:self.testImageCI];
}

- (void)test02UIImageTransformCropWithImage:(UIImage *)testImage {
    CGRect rect = CGRectMake(50, 10, 200, 200);
    UIImage *croppedImage = [testImage tmsd_croppedImageWithRect:rect];
    expect(CGSizeEqualToSize(croppedImage.size, CGSizeMake(200, 200))).beTruthy();
    UIColor *startColor = [croppedImage tmsd_colorAtPoint:CGPointZero];
    expect([startColor.tmsd_hexString isEqualToString:[UIColor clearColor].tmsd_hexString]).beTruthy();
    // Check image not inversion
    UIColor *topCenterColor = [croppedImage tmsd_colorAtPoint:CGPointMake(100, 10)];
    expect([topCenterColor.tmsd_hexString isEqualToString:[UIColor blackColor].tmsd_hexString]).beTruthy();
}

- (void)test03UIImageTransformRoundedCornerCG {
    [self test03UIImageTransformRoundedCornerWithImage:self.testImageCG];
}

- (void)test03UIImageTransformRoundedCornerCI {
    [self test03UIImageTransformRoundedCornerWithImage:self.testImageCI];
}

- (void)test03UIImageTransformRoundedCornerWithImage:(UIImage *)testImage {
    CGFloat radius = 50;
#if TMSD_UIKIT
    TMSDRectCorner corners = UIRectCornerAllCorners;
#else
    TMSDRectCorner corners = TMSDRectCornerAllCorners;
#endif
    CGFloat borderWidth = 1;
    UIColor *borderColor = [UIColor blackColor];
    UIImage *roundedCornerImage = [testImage tmsd_roundedCornerImageWithRadius:radius corners:corners borderWidth:borderWidth borderColor:borderColor];
    expect(CGSizeEqualToSize(roundedCornerImage.size, CGSizeMake(300, 300))).beTruthy();
    UIColor *startColor = [roundedCornerImage tmsd_colorAtPoint:CGPointZero];
    expect([startColor.tmsd_hexString isEqualToString:[UIColor clearColor].tmsd_hexString]).beTruthy();
    // Check the left center pixel, should be border :)
    UIColor *checkBorderColor = [roundedCornerImage tmsd_colorAtPoint:CGPointMake(1, 150)];
    expect([checkBorderColor.tmsd_hexString isEqualToString:borderColor.tmsd_hexString]).beTruthy();
    // Check rounded corner operation not inversion the image
    UIColor *topCenterColor = [roundedCornerImage tmsd_colorAtPoint:CGPointMake(150, 20)];
    expect([topCenterColor.tmsd_hexString isEqualToString:[UIColor blackColor].tmsd_hexString]).beTruthy();
}

- (void)test04UIImageTransformRotateCG {
    [self test04UIImageTransformRotateWithImage:self.testImageCG];
}

- (void)test04UIImageTransformRotateCI {
    [self test04UIImageTransformRotateWithImage:self.testImageCI];
}

- (void)test04UIImageTransformRotateWithImage:(UIImage *)testImage {
    CGFloat angle = M_PI_4;
    UIImage *rotatedImage = [testImage tmsd_rotatedImageWithAngle:angle fitSize:NO];
    // Not fit size and no change
    expect(CGSizeEqualToSize(rotatedImage.size, testImage.size)).beTruthy();
    // Fit size, may change size
    rotatedImage = [testImage tmsd_rotatedImageWithAngle:angle fitSize:YES];
    CGSize rotatedSize = CGSizeMake(ceil(300 * 1.414), ceil(300 * 1.414)); // 45º, square length * sqrt(2)
    expect(rotatedImage.size.width - rotatedSize.width <= 1).beTruthy();
    expect(rotatedImage.size.height - rotatedSize.height <= 1).beTruthy();
    // Check image not inversion
    UIColor *leftCenterColor = [rotatedImage tmsd_colorAtPoint:CGPointMake(60, 175)];
    expect([leftCenterColor.tmsd_hexString isEqualToString:[UIColor blackColor].tmsd_hexString]).beTruthy();
}

- (void)test05UIImageTransformFlipCG {
    [self test05UIImageTransformFlipWithImage:self.testImageCG];
}

- (void)test05UIImageTransformFlipCI {
    [self test05UIImageTransformFlipWithImage:self.testImageCI];
}

- (void)test05UIImageTransformFlipWithImage:(UIImage *)testImage {
    BOOL horizontal = YES;
    BOOL vertical = YES;
    UIImage *flippedImage = [testImage tmsd_flippedImageWithHorizontal:horizontal vertical:vertical];
    expect(CGSizeEqualToSize(flippedImage.size, testImage.size)).beTruthy();
    // Test pixel colors method here
    UIColor *checkColor = [flippedImage tmsd_colorAtPoint:CGPointMake(75, 75)];
    expect(checkColor);
    NSArray<UIColor *> *checkColors = [flippedImage tmsd_colorsWithRect:CGRectMake(75, 75, 10, 10)]; // Rect are all same color
    expect(checkColors.count).to.equal(10 * 10);
    for (UIColor *color in checkColors) {
        expect([color isEqual:checkColor]).to.beTruthy();
    }
    // Check image not inversion
    UIColor *bottomCenterColor = [flippedImage tmsd_colorAtPoint:CGPointMake(150, 285)];
    expect([bottomCenterColor.tmsd_hexString isEqualToString:[UIColor blackColor].tmsd_hexString]).beTruthy();
}

- (void)test06UIImageTransformTintCG {
    [self test06UIImageTransformTintWithImage:self.testImageCG];
}

- (void)test06UIImageTransformTintCI {
    [self test06UIImageTransformTintWithImage:self.testImageCI];
}

- (void)test06UIImageTransformTintWithImage:(UIImage *)testImage {
    UIColor *tintColor = [UIColor blackColor];
    UIImage *tintedImage = [testImage tmsd_tintedImageWithColor:tintColor];
    expect(CGSizeEqualToSize(tintedImage.size, testImage.size)).beTruthy();
    // Check center color, should keep clear
    UIColor *centerColor = [tintedImage tmsd_colorAtPoint:CGPointMake(150, 150)];
    expect([centerColor.tmsd_hexString isEqualToString:[UIColor clearColor].tmsd_hexString]).beTruthy();
    // Check left color, should be tinted
    UIColor *leftColor = [tintedImage tmsd_colorAtPoint:CGPointMake(80, 150)];
    expect([leftColor.tmsd_hexString isEqualToString:tintColor.tmsd_hexString]).beTruthy();
    // Check rounded corner operation not inversion the image
    UIColor *topCenterColor = [tintedImage tmsd_colorAtPoint:CGPointMake(150, 20)];
    expect([topCenterColor.tmsd_hexString isEqualToString:[UIColor blackColor].tmsd_hexString]).beTruthy();
}

- (void)test07UIImageTransformBlurCG {
    [self test07UIImageTransformBlurWithImage:self.testImageCG];
}

- (void)test07UIImageTransformBlurCI {
    [self test07UIImageTransformBlurWithImage:self.testImageCI];
}

- (void)test07UIImageTransformBlurWithImage:(UIImage *)testImage {
    CGFloat radius = 25;
    UIImage *blurredImage = [testImage tmsd_blurredImageWithRadius:radius];
    expect(CGSizeEqualToSize(blurredImage.size, testImage.size)).beTruthy();
    // Check left color, should be blurred
    UIColor *leftColor = [blurredImage tmsd_colorAtPoint:CGPointMake(80, 150)];
    // Hard-code from the output, allows a little deviation because of blur diffs between OS versions :)
    // rgba(114, 27, 23, 0.75)
    UIColor *expectedColor = [UIColor colorWithRed:114.0/255.0 green:27.0/255.0 blue:23.0/255.0 alpha:0.75];
    CGFloat r1, g1, b1, a1;
    CGFloat r2, g2, b2, a2;
    [leftColor getRed:&r1 green:&g1 blue:&b1 alpha:&a1];
    [expectedColor getRed:&r2 green:&g2 blue:&b2 alpha:&a2];
    expect(r1).beCloseToWithin(r2, 2.0/255.0);
    expect(g1).beCloseToWithin(g2, 2.0/255.0);
    expect(b1).beCloseToWithin(b2, 2.0/255.0);
    expect(a1).beCloseToWithin(a2, 2.0/255.0);
    // Check rounded corner operation not inversion the image
    UIColor *topCenterColor = [blurredImage tmsd_colorAtPoint:CGPointMake(150, 20)];
    UIColor *bottomCenterColor = [blurredImage tmsd_colorAtPoint:CGPointMake(150, 280)];
    expect([topCenterColor.tmsd_hexString isEqualToString:bottomCenterColor.tmsd_hexString]).beFalsy();
}

- (void)test08UIImageTransformFilterCG {
    [self test08UIImageTransformFilterWithImage:self.testImageCG];
}

- (void)test08UIImageTransformFilterCI {
    [self test08UIImageTransformFilterWithImage:self.testImageCI];
}

- (void)test08UIImageTransformFilterWithImage:(UIImage *)testImage {
    // Invert color filter
    CIFilter *filter = [CIFilter filterWithName:@"CIColorInvert"];
    UIImage *filteredImage = [testImage tmsd_filteredImageWithFilter:filter];
    expect(CGSizeEqualToSize(filteredImage.size, testImage.size)).beTruthy();
    // Check left color, should be inverted
    UIColor *leftColor = [filteredImage tmsd_colorAtPoint:CGPointMake(80, 150)];
    // Hard-code from the output
    UIColor *expectedColor = [UIColor colorWithRed:0.85098 green:0.992157 blue:0.992157 alpha:1];
    expect([leftColor.tmsd_hexString isEqualToString:expectedColor.tmsd_hexString]).beTruthy();
    // Check rounded corner operation not inversion the image
    UIColor *topCenterColor = [filteredImage tmsd_colorAtPoint:CGPointMake(150, 20)];
    expect([topCenterColor.tmsd_hexString isEqualToString:[UIColor whiteColor].tmsd_hexString]).beTruthy();
}

#pragma mark - TMSDImageTransformer

- (void)test09ImagePipelineTransformer {
    CGSize size = CGSizeMake(100, 100);
    TMSDImageScaleMode scaleMode = TMSDImageScaleModeAspectFill;
    CGFloat angle = M_PI_4;
    BOOL fitSize = NO;
    CGFloat radius = 50;
#if TMSD_UIKIT
    TMSDRectCorner corners = UIRectCornerAllCorners;
#else
    TMSDRectCorner corners = TMSDRectCornerAllCorners;
#endif
    CGFloat borderWidth = 1;
    UIColor *borderCoder = [UIColor blackColor];
    BOOL horizontal = YES;
    BOOL vertical = YES;
    CGRect cropRect = CGRectMake(0, 0, 50, 50);
    UIColor *tintColor = [UIColor clearColor];
    CGFloat blurRadius = 5;
    
    TMSDImageResizingTransformer *transformer1 = [TMSDImageResizingTransformer transformerWithSize:size scaleMode:scaleMode];
    TMSDImageRotationTransformer *transformer2 = [TMSDImageRotationTransformer transformerWithAngle:angle fitSize:fitSize];
    TMSDImageRoundCornerTransformer *transformer3 = [TMSDImageRoundCornerTransformer transformerWithRadius:radius corners:corners borderWidth:borderWidth borderColor:borderCoder];
    TMSDImageFlippingTransformer *transformer4 = [TMSDImageFlippingTransformer transformerWithHorizontal:horizontal vertical:vertical];
    TMSDImageCroppingTransformer *transformer5 = [TMSDImageCroppingTransformer transformerWithRect:cropRect];
    TMSDImageTintTransformer *transformer6 = [TMSDImageTintTransformer transformerWithColor:tintColor];
    TMSDImageBlurTransformer *transformer7 = [TMSDImageBlurTransformer transformerWithRadius:blurRadius];
    
    CIFilter *filter = [CIFilter filterWithName:@"CIColorInvert"];
    TMSDImageFilterTransformer *transformer8 = [TMSDImageFilterTransformer transformerWithFilter:filter];
    
    // Chain all built-in transformers for test case
    TMSDImagePipelineTransformer *pipelineTransformer = [TMSDImagePipelineTransformer transformerWithTransformers:@[
                                                                                                                transformer1,
                                                                                                                transformer2,
                                                                                                                transformer3,
                                                                                                                transformer4,
                                                                                                                transformer5,
                                                                                                                transformer6,
                                                                                                                transformer7,
                                                                                                                transformer8
                                                                                                                ]];
    NSArray *transformerKeys = @[
                      @"TMSDImageResizingTransformer({100.000000,100.000000},2)",
                      @"TMSDImageRotationTransformer(0.785398,0)",
                      @"TMSDImageRoundCornerTransformer(50.000000,18446744073709551615,1.000000,#ff000000)",
                      @"TMSDImageFlippingTransformer(1,1)",
                      @"TMSDImageCroppingTransformer({0.000000,0.000000,50.000000,50.000000})",
                      @"TMSDImageTintTransformer(#00000000)",
                      @"TMSDImageBlurTransformer(5.000000)",
                      @"TMSDImageFilterTransformer(CIColorInvert)"
                      ];
    NSString *transformerKey = [transformerKeys componentsJoinedByString:@"-"]; // TMSDImageTransformerKeySeparator
    expect([pipelineTransformer.transformerKey isEqualToString:transformerKey]).beTruthy();
    
    UIImage *transformedImage = [pipelineTransformer transformedImageWithImage:self.testImageCG forKey:@"Test"];
    expect(transformedImage).notTo.beNil();
    expect(CGSizeEqualToSize(transformedImage.size, cropRect.size)).beTruthy();
}

- (void)test10TransformerKeyForCacheKey {
    NSString *transformerKey = @"TMSDImageFlippingTransformer(1,0)";
    
    // File path representation test cases
    NSString *key = @"image.png";
    expect(TMSDTransformedKeyForKey(key, transformerKey)).equal(@"image-TMSDImageFlippingTransformer(1,0).png");
    
    key = @"image";
    expect(TMSDTransformedKeyForKey(key, transformerKey)).equal(@"image-TMSDImageFlippingTransformer(1,0)");
    
    key = @".image";
    expect(TMSDTransformedKeyForKey(key, transformerKey)).equal(@".image-TMSDImageFlippingTransformer(1,0)");
    
    key = @"image.";
    expect(TMSDTransformedKeyForKey(key, transformerKey)).equal(@"image.-TMSDImageFlippingTransformer(1,0)");
    
    key = @"Test/image.png";
    expect(TMSDTransformedKeyForKey(key, transformerKey)).equal(@"Test/image-TMSDImageFlippingTransformer(1,0).png");
    
    // URL representation test cases
    key = @"http://foo/image.png";
    expect(TMSDTransformedKeyForKey(key, transformerKey)).equal(@"http://foo/image-TMSDImageFlippingTransformer(1,0).png");
    
    key = @"http://foo/image";
    expect(TMSDTransformedKeyForKey(key, transformerKey)).equal(@"http://foo/image-TMSDImageFlippingTransformer(1,0)");
    
    key = @"http://foo/.image";
    expect(TMSDTransformedKeyForKey(key, transformerKey)).equal(@"http://foo/.image-TMSDImageFlippingTransformer(1,0)");
    
    key = @"http://foo/image.png?foo=bar#mark";
    expect(TMSDTransformedKeyForKey(key, transformerKey)).equal(@"http://foo/image-TMSDImageFlippingTransformer(1,0).png?foo=bar#mark");
    
    key = @"ftp://root:password@foo.com/image.png";
    expect(TMSDTransformedKeyForKey(key, transformerKey)).equal(@"ftp://root:password@foo.com/image-TMSDImageFlippingTransformer(1,0).png");
}

#pragma mark - Coder Helper

- (void)test20CGImageCreateDecodedWithOrientation {
    // Test EXIF orientation tag, you can open this image with `Preview.app`, open inspector (Command+I) and rotate (Command+L/R) to check
    UIImage *image = [[UIImage alloc] initWithContentsOfFile:[self testPNGPathForName:@"TestEXIF"]];
    CGImageRef originalCGImage = image.CGImage;
    expect(image).notTo.beNil();
    
    // Check the longest side of "F" point color
    UIColor *pointColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:1];
    
    CGImageRef upCGImage = [TMSDImageCoderHelper CGImageCreateDecoded:originalCGImage orientation:kCGImagePropertyOrientationUp];
#if TMSD_UIKIT
    UIImage *upImage = [[UIImage alloc] initWithCGImage:upCGImage];
#else
    UIImage *upImage = [[UIImage alloc] initWithCGImage:upCGImage size:NSZeroSize];
#endif
    expect([[upImage tmsd_colorAtPoint:CGPointMake(40, 160)].tmsd_hexString isEqualToString:pointColor.tmsd_hexString]).beTruthy();
    expect(upImage.size).equal(CGSizeMake(150, 200));
    CGImageRelease(upCGImage);
    
    CGImageRef upMirroredCGImage = [TMSDImageCoderHelper CGImageCreateDecoded:originalCGImage orientation:kCGImagePropertyOrientationUpMirrored];
#if TMSD_UIKIT
    UIImage *upMirroredImage = [[UIImage alloc] initWithCGImage:upMirroredCGImage];
#else
    UIImage *upMirroredImage = [[UIImage alloc] initWithCGImage:upMirroredCGImage size:NSZeroSize];
#endif
    expect([[upMirroredImage tmsd_colorAtPoint:CGPointMake(110, 160)].tmsd_hexString isEqualToString:pointColor.tmsd_hexString]).beTruthy();
    expect(upMirroredImage.size).equal(CGSizeMake(150, 200));
    CGImageRelease(upMirroredCGImage);
    
    CGImageRef downCGImage = [TMSDImageCoderHelper CGImageCreateDecoded:originalCGImage orientation:kCGImagePropertyOrientationDown];
#if TMSD_UIKIT
    UIImage *downImage = [[UIImage alloc] initWithCGImage:downCGImage];
#else
    UIImage *downImage = [[UIImage alloc] initWithCGImage:downCGImage size:NSZeroSize];
#endif
    expect([[downImage tmsd_colorAtPoint:CGPointMake(110, 30)].tmsd_hexString isEqualToString:pointColor.tmsd_hexString]).beTruthy();
    expect(downImage.size).equal(CGSizeMake(150, 200));
    CGImageRelease(downCGImage);
    
    CGImageRef downMirrorerdCGImage = [TMSDImageCoderHelper CGImageCreateDecoded:originalCGImage orientation:kCGImagePropertyOrientationDownMirrored];
#if TMSD_UIKIT
    UIImage *downMirroredImage = [[UIImage alloc] initWithCGImage:downMirrorerdCGImage];
#else
    UIImage *downMirroredImage = [[UIImage alloc] initWithCGImage:downMirrorerdCGImage size:NSZeroSize];
#endif
    expect([[downMirroredImage tmsd_colorAtPoint:CGPointMake(40, 30)].tmsd_hexString isEqualToString:pointColor.tmsd_hexString]).beTruthy();
    expect(downMirroredImage.size).equal(CGSizeMake(150, 200));
    CGImageRelease(downMirrorerdCGImage);
    
    CGImageRef leftMirroredCGImage = [TMSDImageCoderHelper CGImageCreateDecoded:originalCGImage orientation:kCGImagePropertyOrientationLeftMirrored];
#if TMSD_UIKIT
    UIImage *leftMirroredImage = [[UIImage alloc] initWithCGImage:leftMirroredCGImage];
#else
    UIImage *leftMirroredImage = [[UIImage alloc] initWithCGImage:leftMirroredCGImage size:NSZeroSize];
#endif
    expect([[leftMirroredImage tmsd_colorAtPoint:CGPointMake(160, 40)].tmsd_hexString isEqualToString:pointColor.tmsd_hexString]).beTruthy();
    expect(leftMirroredImage.size).equal(CGSizeMake(200, 150));
    CGImageRelease(leftMirroredCGImage);
    
    CGImageRef rightCGImage = [TMSDImageCoderHelper CGImageCreateDecoded:originalCGImage orientation:kCGImagePropertyOrientationRight];
#if TMSD_UIKIT
    UIImage *rightImage = [[UIImage alloc] initWithCGImage:rightCGImage];
#else
    UIImage *rightImage = [[UIImage alloc] initWithCGImage:rightCGImage size:NSZeroSize];
#endif
    expect([[rightImage tmsd_colorAtPoint:CGPointMake(30, 40)].tmsd_hexString isEqualToString:pointColor.tmsd_hexString]).beTruthy();
    expect(rightImage.size).equal(CGSizeMake(200, 150));
    CGImageRelease(rightCGImage);
    
    CGImageRef rightMirroredCGImage = [TMSDImageCoderHelper CGImageCreateDecoded:originalCGImage orientation:kCGImagePropertyOrientationRightMirrored];
#if TMSD_UIKIT
    UIImage *rightMirroredImage = [[UIImage alloc] initWithCGImage:rightMirroredCGImage];
#else
    UIImage *rightMirroredImage = [[UIImage alloc] initWithCGImage:rightMirroredCGImage size:NSZeroSize];
#endif
    expect([[rightMirroredImage tmsd_colorAtPoint:CGPointMake(30, 110)].tmsd_hexString isEqualToString:pointColor.tmsd_hexString]).beTruthy();
    expect(rightMirroredImage.size).equal(CGSizeMake(200, 150));
    CGImageRelease(rightMirroredCGImage);
    
    CGImageRef leftCGImage = [TMSDImageCoderHelper CGImageCreateDecoded:originalCGImage orientation:kCGImagePropertyOrientationLeft];
#if TMSD_UIKIT
    UIImage *leftImage = [[UIImage alloc] initWithCGImage:leftCGImage];
#else
    UIImage *leftImage = [[UIImage alloc] initWithCGImage:leftCGImage size:NSZeroSize];
#endif
    expect([[leftImage tmsd_colorAtPoint:CGPointMake(160, 110)].tmsd_hexString isEqualToString:pointColor.tmsd_hexString]).beTruthy();
    expect(leftImage.size).equal(CGSizeMake(200, 150));
    CGImageRelease(leftCGImage);
}

- (void)test21BMPImageCreateDecodedShouldNotBlank {
    UIImage *testImage = [[UIImage alloc] initWithContentsOfFile:[self testBMPPathForName:@"TestImage"]];
    CGImageRef cgImage = testImage.CGImage;
    expect(cgImage).notTo.beNil();
    UIImage *decodedImage = [TMSDImageCoderHelper decodedImageWithImage:testImage];
    expect(decodedImage).notTo.beNil();
    UIColor *testColor = [decodedImage tmsd_colorAtPoint:CGPointMake(100, 100)];
    // Should not be black color
    expect([[testColor tmsd_hexString] isEqualToString:UIColor.blackColor.tmsd_hexString]).beFalsy();
}

#pragma mark - Helper

- (UIImage *)testImageCG {
    if (!_testImageCG) {
        _testImageCG = [[UIImage alloc] initWithContentsOfFile:[self testPNGPathForName:@"TestImage"]];
    }
    return _testImageCG;
}

- (UIImage *)testImageCI {
    if (!_testImageCI) {
        CIImage *ciImage = [[CIImage alloc] initWithContentsOfURL:[NSURL fileURLWithPath:[self testPNGPathForName:@"TestImage"]]];
#if TMSD_UIKIT
        _testImageCI = [[UIImage alloc] initWithCIImage:ciImage scale:1 orientation:UIImageOrientationUp];
#else
        _testImageCI = [[UIImage alloc] initWithCIImage:ciImage scale:1 orientation:kCGImagePropertyOrientationUp];
#endif
    }
    return _testImageCI;
}

- (NSString *)testPNGPathForName:(NSString *)name {
    NSBundle *testBundle = [NSBundle bundleForClass:[self class]];
    return [testBundle pathForResource:name ofType:@"png"];
}

- (NSString *)testBMPPathForName:(NSString *)name {
  NSBundle *testBundle = [NSBundle bundleForClass:[self class]];
  return [testBundle pathForResource:name ofType:@"bmp"];
}

@end
