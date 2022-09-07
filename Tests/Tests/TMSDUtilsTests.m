/*
 * This file is part of the TMSDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 * (c) Matt Galloway
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import <TMSDWebImage/TMSDTestCase.h>
#import <TMSDWebImage/TMSDWeakProxy.h>
#import <TMSDWebImage/TMSDDisplayLink.h>
#import <TMSDWebImage/TMSDInternalMacros.h>
#import <TMSDWebImage/TMSDFileAttributeHelper.h>
#import <TMSDWebImage/UIColor+TMSDHexString.h>

@interface TMSDUtilsTests : TMSDTestCase

@end

@implementation TMSDUtilsTests

- (void)testSDWeakProxy {
    NSObject *object = [NSObject new];
    TMSDWeakProxy *proxy = [TMSDWeakProxy proxyWithTarget:object];
    SEL sel = @selector(hash);
    NSMethodSignature *signature = [proxy methodSignatureForSelector:sel];
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
    [proxy forwardInvocation:invocation];
    void *returnValue;
    [invocation getReturnValue:&returnValue];
    expect(returnValue).beNil();
    expect([((NSObject *)proxy) forwardingTargetForSelector:sel]).equal(object);
    expect(proxy.isProxy).beTruthy();
    expect([proxy respondsToSelector:sel]).equal([object respondsToSelector:sel]);
    expect([proxy isEqual:object]).beTruthy();
    expect(proxy.hash).equal(object.hash);
    expect(proxy.superclass).equal(object.superclass);
    expect(proxy.class).equal(object.class);
    expect([proxy isKindOfClass:NSObject.class]).equal([object isKindOfClass:NSObject.class]);
    expect([proxy isMemberOfClass:NSObject.class]).equal([object isMemberOfClass:NSObject.class]);
    expect([proxy conformsToProtocol:@protocol(NSObject)]).equal([object conformsToProtocol:@protocol(NSObject)]);
    expect([proxy.description isEqualToString:object.description]).beTruthy();
    expect([proxy.debugDescription isEqualToString:object.debugDescription]).beTruthy();
}

- (void)testSDDisplayLink {
    XCTestExpectation *expectation1 = [self expectationWithDescription:@"Display Link Stop"];
    XCTestExpectation *expectation2 = [self expectationWithDescription:@"Display Link Start"];
    TMSDDisplayLink *displayLink = [TMSDDisplayLink displayLinkWithTarget:self selector:@selector(displayLinkDidRefresh:)];
    NSTimeInterval duration = displayLink.duration; // Initial value
    expect(duration).equal(1.0 / 60);
    [displayLink addToRunLoop:NSRunLoop.mainRunLoop forMode:NSRunLoopCommonModes];
    [displayLink start];
    expect(displayLink.isRunning).beTruthy();
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        expect(displayLink.isRunning).beTruthy();
        [displayLink stop];
    });
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        expect(displayLink.isRunning).beFalsy();
        [displayLink start];
        [expectation1 fulfill];
    });
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        expect(displayLink.isRunning).beTruthy();
        [displayLink stop];
        [expectation2 fulfill];
    });
    [self waitForExpectationsWithCommonTimeout];
}

- (void)displayLinkDidRefresh:(TMSDDisplayLink *)displayLink {
    NSTimeInterval duration = displayLink.duration; // Running value
    expect(duration).beGreaterThan(0.001); /// 60Hz ~ 120Hz
    expect(duration).beLessThan(0.02);
}

- (void)testSDFileAttributeHelper {
    NSData *fileData = [@"File Data" dataUsingEncoding:NSUTF8StringEncoding];
    NSData *extendedData = [@"Extended Data" dataUsingEncoding:NSUTF8StringEncoding];
    NSString *filePath = @"/tmp/file.dat";
    [NSFileManager.defaultManager removeItemAtPath:filePath error:nil];
    [fileData writeToFile:filePath atomically:YES];
    BOOL exist = [NSFileManager.defaultManager fileExistsAtPath:filePath];
    expect(exist).beTruthy();
    
    NSArray *names = [TMSDFileAttributeHelper extendedAttributeNamesAtPath:filePath traverseLink:NO error:nil];
    expect(names.count).equal(0);
    
    NSString *attr = @"com.hackemist.test";
    [TMSDFileAttributeHelper setExtendedAttribute:attr value:extendedData atPath:filePath traverseLink:NO overwrite:YES error:nil];
    
    BOOL hasAttr =[TMSDFileAttributeHelper hasExtendedAttribute:attr atPath:filePath traverseLink:NO error:nil];
    expect(hasAttr).beTruthy();
    
    names = [TMSDFileAttributeHelper extendedAttributeNamesAtPath:filePath traverseLink:NO error:nil];
    expect(names.count).equal(1);
    expect(names.firstObject).equal(attr);
    
    NSData *queriedData = [TMSDFileAttributeHelper extendedAttribute:attr atPath:filePath traverseLink:NO error:nil];
    expect(extendedData).equal(queriedData);
    
    BOOL removed = [TMSDFileAttributeHelper removeExtendedAttribute:attr atPath:filePath traverseLink:NO error:nil];
    expect(removed).beTruthy();
    
    hasAttr = [TMSDFileAttributeHelper hasExtendedAttribute:attr atPath:filePath traverseLink:NO error:nil];
    expect(hasAttr).beFalsy();
}

- (void)testSDGraphicsImageRenderer {
    // Main Screen
    TMSDGraphicsImageRendererFormat *format = TMSDGraphicsImageRendererFormat.preferredFormat;
#if TMSD_UIKIT
    CGFloat screenScale = [UIScreen mainScreen].scale;
#elif TMSD_MAC
    CGFloat screenScale = [NSScreen mainScreen].backingScaleFactor;
#endif
    expect(format.scale).equal(screenScale);
    expect(format.opaque).beFalsy();
#if TMSD_UIKIT
    expect(format.preferredRange).equal(TMSDGraphicsImageRendererFormatRangeAutomatic);
#elif TMSD_MAC
    expect(format.preferredRange).equal(TMSDGraphicsImageRendererFormatRangeStandard);
#endif
    CGSize size = CGSizeMake(100, 100);
    TMSDGraphicsImageRenderer *renderer = [[TMSDGraphicsImageRenderer alloc] initWithSize:size format:format];
    UIColor *color = UIColor.redColor;
    UIImage *image = [renderer imageWithActions:^(CGContextRef  _Nonnull context) {
        CGContextSetFillColorWithColor(context, [color CGColor]);
        CGContextFillRect(context, CGRectMake(0, 0, size.width, size.height));
    }];
    expect(image.scale).equal(format.scale);
    expect([image tmsd_colorAtPoint:CGPointMake(50, 50)].tmsd_hexString).equal(color.tmsd_hexString);
    
    UIColor *grayscaleColor = UIColor.blackColor;
    UIImage *grayscaleImage = [renderer imageWithActions:^(CGContextRef  _Nonnull context) {
        CGContextSetFillColorWithColor(context, [grayscaleColor CGColor]);
        CGContextFillRect(context, CGRectMake(0, 0, size.width, size.height));
    }];
    expect([grayscaleImage tmsd_colorAtPoint:CGPointMake(50, 50)].tmsd_hexString).equal(grayscaleColor.tmsd_hexString);
}

- (void)testSDScaledImageForKey {
    // Test nil
    expect(TMSDScaledImageForKey(nil, nil)).beNil();
    // Test @2x
    NSData *data = [NSData dataWithContentsOfFile:[self testGIFPath]];
    UIImage * image = [UIImage tmsd_imageWithGIFData:data];
    expect(image.tmsd_isAnimated).beTruthy();
    expect(image.scale).equal(1);
    
    UIImage *scaledImage = TMSDScaledImageForKey(@"test@2x.gif", image);
    expect(scaledImage.scale).equal(2);
}

- (void)testInternalMacro {
    @weakify(self);
    @onExit {
        @strongify(self);
        expect(self).notTo.beNil();
    };
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
