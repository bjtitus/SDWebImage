/*
 * This file is part of the TMSDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 * (c) Matt Galloway
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import <TMSDWebImage/TMSDTestCase.h>
#if TMSD_UIKIT
#import <MobileCoreServices/MobileCoreServices.h>
#endif
#import <TMSDWebImage/TMSDImageIOAnimatedCoderInternal.h>

@interface TMSDCategoriesTests : TMSDTestCase

@end

@implementation TMSDCategoriesTests

- (void)test01NSDataImageContentTypeCategory {
    // Test invalid image data
    TMSDImageFormat format = [NSData tmsd_imageFormatForImageData:nil];
    expect(format == TMSDImageFormatUndefined);
    
    // Test invalid format
    CFStringRef type = [NSData tmsd_UTTypeFromImageFormat:TMSDImageFormatUndefined];
    expect(CFStringCompare(kSDUTTypeImage, type, 0)).equal(kCFCompareEqualTo);
    expect([NSData tmsd_imageFormatFromUTType:kSDUTTypeImage]).equal(TMSDImageFormatUndefined);
}

- (void)test02UIImageMultiFormatCategory {
    // Test invalid image data
    UIImage *image = [UIImage tmsd_imageWithData:nil];
    expect(image).to.beNil();
    // Test image encode
    image = [[UIImage alloc] initWithContentsOfFile:[self testJPEGPath]];
    NSData *data = [image tmsd_imageData];
    expect(data).notTo.beNil();
    // Test image encode PNG
    data = [image tmsd_imageDataAsFormat:TMSDImageFormatPNG];
    expect(data).notTo.beNil();
    // Test image decode PNG
    expect([UIImage tmsd_imageWithData:data scale:1 firstFrameOnly:YES]).notTo.beNil();
    // Test image encode JPEG with compressionQuality
    NSData *jpegData1 = [image tmsd_imageDataAsFormat:TMSDImageFormatJPEG compressionQuality:1];
    NSData *jpegData2 = [image tmsd_imageDataAsFormat:TMSDImageFormatJPEG compressionQuality:0.5];
    expect(jpegData1).notTo.beNil();
    expect(jpegData2).notTo.beNil();
    expect(jpegData1.length).notTo.equal(jpegData2.length);
}

- (void)test03UIImageGIFCategory {
    // Test invalid image data
    UIImage *image = [UIImage tmsd_imageWithGIFData:nil];
    expect(image).to.beNil();
    // Test valid image data
    NSData *data = [NSData dataWithContentsOfFile:[self testGIFPath]];
    image = [UIImage tmsd_imageWithGIFData:data];
    expect(image).notTo.beNil();
    expect(image.tmsd_isAnimated).beTruthy();
    expect(image.tmsd_imageFrameCount).equal(5);
}

#pragma mark - Helper

- (NSString *)testJPEGPath {
    NSBundle *testBundle = [NSBundle bundleForClass:[self class]];
    return [testBundle pathForResource:@"TestImage" ofType:@"jpg"];
}

- (NSString *)testGIFPath {
    NSBundle *testBundle = [NSBundle bundleForClass:[self class]];
    return [testBundle pathForResource:@"TestImage" ofType:@"gif"];
}

@end
