/*
 * This file is part of the TMSDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 * (c) Matt Galloway
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import <TMSDWebImage/TMSDWebImageTestCoder.h>

@implementation TMSDWebImageTestCoder

- (BOOL)canDecodeFromData:(nullable NSData *)data {
    return YES;
}

- (BOOL)canEncodeToFormat:(TMSDImageFormat)format {
    return YES;
}

- (UIImage *)decodedImageWithData:(NSData *)data options:(nullable TMSDImageCoderOptions *)options {
    NSString * testImagePath = [[NSBundle bundleForClass:[self class]] pathForResource:@"TestImage" ofType:@"jpg"];
    UIImage *image = [[UIImage alloc] initWithContentsOfFile:testImagePath];
    return image;
}

- (instancetype)initIncrementalWithOptions:(nullable TMSDImageCoderOptions *)options
{
    self = [super init];
    if (self) {
    }
    return self;
}

- (void)updateIncrementalData:(NSData *)data finished:(BOOL)finished {
    return;
}

- (UIImage *)incrementalDecodedImageWithOptions:(TMSDImageCoderOptions *)options {
    NSString * testImagePath = [[NSBundle bundleForClass:[self class]] pathForResource:@"TestImage" ofType:@"gif"];
    UIImage *image = [[UIImage alloc] initWithContentsOfFile:testImagePath];
    return image;
}

- (BOOL)canIncrementalDecodeFromData:(NSData *)data {
    return YES;
}

- (NSData *)encodedDataWithImage:(UIImage *)image format:(TMSDImageFormat)format options:(nullable TMSDImageCoderOptions *)options {
    NSString *testString = @"TestEncode";
    NSData *data = [testString dataUsingEncoding:NSUTF8StringEncoding];
    return data;
}

@end
