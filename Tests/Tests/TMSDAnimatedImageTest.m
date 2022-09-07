/*
 * This file is part of the TMSDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 * (c) Matt Galloway
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import <TMSDWebImage/TMSDTestCase.h>
#import <TMSDWebImage/TMSDInternalMacros.h>
#import <KVOController/KVOController.h>
#import <TMSDWebImageWebPCoder/TMSDWebImageWebPCoder.h>

static const NSUInteger kTestGIFFrameCount = 5; // local TestImage.gif loop count

// Check whether the coder is called
@interface TMSDImageAPNGTestCoder : TMSDImageAPNGCoder

@property (nonatomic, class, assign) BOOL isCalled;

@end

@implementation TMSDImageAPNGTestCoder

static BOOL _isCalled;

+ (BOOL)isCalled {
    return _isCalled;
}

+ (void)setIsCalled:(BOOL)isCalled {
    _isCalled = isCalled;
}

+ (instancetype)sharedCoder {
    static TMSDImageAPNGTestCoder *coder;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        coder = [[TMSDImageAPNGTestCoder alloc] init];
    });
    return coder;
}

- (instancetype)initWithAnimatedImageData:(NSData *)data options:(TMSDImageCoderOptions *)options {
    TMSDImageAPNGTestCoder.isCalled = YES;
    return [super initWithAnimatedImageData:data options:options];
}

@end

// Internal header
@interface TMSDAnimatedImageView ()

@property (nonatomic, assign) BOOL isProgressive;
@property (nonatomic, strong) TMSDAnimatedImagePlayer *player;

@end

@interface TMSDAnimatedImagePlayer ()

@property (nonatomic, strong) NSMutableDictionary<NSNumber *, UIImage *> *frameBuffer;

@end

@interface TMSDAnimatedImageTest : TMSDTestCase

@property (nonatomic, strong) UIWindow *window;

@end

@implementation TMSDAnimatedImageTest

- (void)test01AnimatedImageInitWithData {
    NSData *invalidData = [@"invalid data" dataUsingEncoding:NSUTF8StringEncoding];
    TMSDAnimatedImage *image = [[TMSDAnimatedImage alloc] initWithData:invalidData];
    expect(image).beNil();
    
    NSData *validData = [self testGIFData];
    image = [[TMSDAnimatedImage alloc] initWithData:validData scale:2];
    expect(image).notTo.beNil(); // image
    expect(image.scale).equal(2); // scale
    expect(image.animatedImageData).equal(validData); // data
    expect(image.animatedImageFormat).equal(TMSDImageFormatGIF); // format
    expect(image.animatedImageLoopCount).equal(0); // loop count
    expect(image.animatedImageFrameCount).equal(kTestGIFFrameCount); // frame count
    expect([image animatedImageFrameAtIndex:1]).notTo.beNil(); // 1 frame
}

- (void)test02AnimatedImageInitWithContentsOfFile {
    TMSDAnimatedImage *image = [[TMSDAnimatedImage alloc] initWithContentsOfFile:[self testGIFPath]];
    expect(image).notTo.beNil();
    expect(image.scale).equal(1); // scale
    
    // Test Retina File Path should result @2x scale
    NSBundle *testBundle = [NSBundle bundleForClass:[self class]];
    NSString *testPath = [testBundle pathForResource:@"1@2x" ofType:@"gif"];
    image = [[TMSDAnimatedImage alloc] initWithContentsOfFile:testPath];
    expect(image).notTo.beNil();
    expect(image.scale).equal(2); // scale
}

- (void)test03AnimatedImageInitWithAnimatedCoder {
    NSData *validData = [self testGIFData];
    TMSDImageGIFCoder *coder = [[TMSDImageGIFCoder alloc] initWithAnimatedImageData:validData options:nil];
    TMSDAnimatedImage *image = [[TMSDAnimatedImage alloc] initWithAnimatedCoder:coder scale:1];
    expect(image).notTo.beNil();
    // enough, other can be test with InitWithData
}

- (void)test04AnimatedImageImageNamed {
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    expect([TMSDAnimatedImage imageNamed:@"TestImage.gif"]).beNil(); // Not in main bundle
#if TMSD_UIKIT
    TMSDAnimatedImage *image = [TMSDAnimatedImage imageNamed:@"TestImage.gif" inBundle:bundle compatibleWithTraitCollection:nil];
#else
    TMSDAnimatedImage *image = [TMSDAnimatedImage imageNamed:@"TestImage.gif" inBundle:bundle];
#endif
    expect(image).notTo.beNil();
    expect([image.animatedImageData isEqualToData:[self testGIFData]]).beTruthy();
}

- (void)test05AnimatedImagePreloadFrames {
    NSData *validData = [self testGIFData];
    TMSDAnimatedImage *image = [TMSDAnimatedImage imageWithData:validData];
    
    // Preload all frames
    [image preloadAllFrames];
    
    NSArray *loadedAnimatedImageFrames = [image valueForKey:@"loadedAnimatedImageFrames"]; // Access the internal property, only for test and may be changed in the future
    expect(loadedAnimatedImageFrames.count).equal(kTestGIFFrameCount);
    
    // Test one frame
    UIImage *frame = [image animatedImageFrameAtIndex:0];
    expect(frame).notTo.beNil();
    
    // Unload all frames
    [image unloadAllFrames];
}

- (void)test06AnimatedImageViewSetImage {
    TMSDAnimatedImageView *imageView = [TMSDAnimatedImageView new];
    UIImage *image = [[UIImage alloc] initWithData:[self testJPEGData]];
    imageView.image = image;
    expect(imageView.image).notTo.beNil();
    expect(imageView.currentFrame).beNil(); // current frame
}

- (void)test08AnimatedImageViewSetAnimatedImageGIF {
    TMSDAnimatedImageView *imageView = [TMSDAnimatedImageView new];
    TMSDAnimatedImage *image = [TMSDAnimatedImage imageWithData:[self testGIFData]];
    imageView.image = image;
    expect(imageView.image).notTo.beNil();
    expect(imageView.player).notTo.beNil();
}

- (void)test09AnimatedImageViewSetAnimatedImageAPNG {
    TMSDAnimatedImageView *imageView = [TMSDAnimatedImageView new];
    TMSDAnimatedImage *image = [TMSDAnimatedImage imageWithData:[self testAPNGPData]];
    imageView.image = image;
    expect(imageView.image).notTo.beNil();
    expect(imageView.player).notTo.beNil();
}

- (void)test10AnimatedImageInitWithCoder {
    TMSDAnimatedImage *image1 = [TMSDAnimatedImage imageWithContentsOfFile:[self testGIFPath]];
    expect(image1).notTo.beNil();
    NSMutableData *encodedData = [NSMutableData data];
    NSKeyedArchiver *archiver  = [[NSKeyedArchiver alloc] initForWritingWithMutableData:encodedData];
    archiver.requiresSecureCoding = YES;
    [archiver encodeObject:image1 forKey:NSKeyedArchiveRootObjectKey];
    [archiver finishEncoding];
    expect(encodedData).notTo.beNil();
    NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:encodedData];
    unarchiver.requiresSecureCoding = YES;
    TMSDAnimatedImage *image2 = [unarchiver decodeObjectOfClass:TMSDAnimatedImage.class forKey:NSKeyedArchiveRootObjectKey];
    [unarchiver finishDecoding];
    expect(image2).notTo.beNil();
    
    // Check each property
    expect(image1.scale).equal(image2.scale);
    expect(image1.size).equal(image2.size);
    expect(image1.animatedImageFormat).equal(image2.animatedImageFormat);
    expect(image1.animatedImageData).equal(image2.animatedImageData);
    expect(image1.animatedImageLoopCount).equal(image2.animatedImageLoopCount);
    expect(image1.animatedImageFrameCount).equal(image2.animatedImageFrameCount);
}

- (void)test11AnimatedImageViewIntrinsicContentSize {
    // Test that TMSDAnimatedImageView.intrinsicContentSize return the correct value of image size
    TMSDAnimatedImageView *imageView = [TMSDAnimatedImageView new];
    TMSDAnimatedImage *image = [TMSDAnimatedImage imageWithData:[self testAPNGPData]];
    imageView.image = image;
    expect(imageView.intrinsicContentSize).equal(image.size);
}

- (void)test12AnimatedImageViewLayerContents {
    // Test that TMSDAnimatedImageView with built-in UIImage/NSImage will actually setup the layer for display
    TMSDAnimatedImageView *imageView = [TMSDAnimatedImageView new];
    UIImage *image = [[UIImage alloc] initWithData:[self testJPEGData]];
    imageView.image = image;
#if TMSD_MAC
    expect(imageView.wantsUpdateLayer).beTruthy();
#else
    expect(imageView.layer).notTo.beNil();
#endif
}

- (void)test13AnimatedImageViewInitWithImage {
    // Test that -[TMSDAnimatedImageView initWithImage:] this convenience initializer not crash
    TMSDAnimatedImage *image = [TMSDAnimatedImage imageWithData:[self testAPNGPData]];
    TMSDAnimatedImageView *imageView;
#if TMSD_UIKIT
    imageView = [[TMSDAnimatedImageView alloc] initWithImage:image];
#else
    if (@available(macOS 10.12, *)) {
        imageView = [TMSDAnimatedImageView imageViewWithImage:image];
    }
#endif
    expect(imageView.image).equal(image);
}

- (void)test14AnimatedImageViewStopPlayingWhenHidden {
    TMSDAnimatedImageView *imageView = [TMSDAnimatedImageView new];
#if TMSD_UIKIT
    [self.window addSubview:imageView];
#else
    [self.window.contentView addSubview:imageView];
#endif
    TMSDAnimatedImage *image = [TMSDAnimatedImage imageWithData:[self testGIFData]];
    imageView.image = image;
#if TMSD_UIKIT
    [imageView startAnimating];
#else
    imageView.animates = YES;
#endif
    TMSDAnimatedImagePlayer *player = imageView.player;
    expect(player).notTo.beNil();
    expect(player.isPlaying).beTruthy();
    imageView.hidden = YES;
    expect(player.isPlaying).beFalsy();
}

- (void)test20AnimatedImageViewRendering {
    XCTestExpectation *expectation = [self expectationWithDescription:@"test TMSDAnimatedImageView rendering"];
    TMSDAnimatedImageView *imageView = [[TMSDAnimatedImageView alloc] init];
#if TMSD_UIKIT
    [self.window addSubview:imageView];
#else
    [self.window.contentView addSubview:imageView];
#endif
    
    NSMutableDictionary *frames = [NSMutableDictionary dictionaryWithCapacity:kTestGIFFrameCount];
    
    [self.KVOController observe:imageView keyPaths:@[NSStringFromSelector(@selector(currentFrameIndex)), NSStringFromSelector(@selector(currentLoopCount))] options:NSKeyValueObservingOptionNew block:^(id  _Nullable observer, id  _Nonnull object, NSDictionary<NSString *,id> * _Nonnull change) {
        NSUInteger frameIndex = imageView.currentFrameIndex;
        NSUInteger loopCount = imageView.currentLoopCount;
        [frames setObject:@(YES) forKey:@(frameIndex)];
        
        BOOL framesRendered = NO;
        if (frames.count >= kTestGIFFrameCount) {
            // All frames rendered
            framesRendered = YES;
        }
        BOOL loopFinished = NO;
        if (loopCount >= 1) {
            // One loop finished
            loopFinished = YES;
        }
        if (framesRendered && loopFinished) {
#if TMSD_UIKIT
            [imageView stopAnimating];
#else
            imageView.animates = NO;
#endif
            [imageView removeFromSuperview];
            [expectation fulfill];
        }
    }];
    
    TMSDAnimatedImage *image = [TMSDAnimatedImage imageWithData:[self testGIFData]];
    imageView.image = image;
    
    [self waitForExpectationsWithCommonTimeout];
}

- (void)test21AnimatedImageViewSetProgressiveAnimatedImage {
    NSData *gifData = [self testGIFData];
    TMSDImageGIFCoder *progressiveCoder = [[TMSDImageGIFCoder alloc] initIncrementalWithOptions:nil];
    // simulate progressive decode, pass partial data
    NSData *partialData = [gifData subdataWithRange:NSMakeRange(0, gifData.length - 1)];
    [progressiveCoder updateIncrementalData:partialData finished:NO];
    
    TMSDAnimatedImage *partialImage = [[TMSDAnimatedImage alloc] initWithAnimatedCoder:progressiveCoder scale:1];
    partialImage.tmsd_isIncremental = YES;
    
    TMSDAnimatedImageView *imageView = [[TMSDAnimatedImageView alloc] init];
    imageView.image = partialImage;
    
    BOOL isProgressive = imageView.isProgressive;
    expect(isProgressive).equal(YES);
    
    // pass full data
    [progressiveCoder updateIncrementalData:gifData finished:YES];
    
    TMSDAnimatedImage *fullImage = [[TMSDAnimatedImage alloc] initWithAnimatedCoder:progressiveCoder scale:1];
    
    imageView.image = fullImage;
    
    isProgressive = imageView.isProgressive;
    expect(isProgressive).equal(NO);
}

- (void)test22AnimatedImageViewCategory {
    XCTestExpectation *expectation = [self expectationWithDescription:@"test TMSDAnimatedImageView view category"];
    TMSDAnimatedImageView *imageView = [TMSDAnimatedImageView new];
    NSURL *testURL = [NSURL URLWithString:kTestGIFURL];
    [imageView tmsd_setImageWithURL:testURL completed:^(UIImage * _Nullable image, NSError * _Nullable error, TMSDImageCacheType cacheType, NSURL * _Nullable imageURL) {
        expect(error).to.beNil();
        expect(image).notTo.beNil();
        expect([image isKindOfClass:[TMSDAnimatedImage class]]).beTruthy();
        [expectation fulfill];
    }];
    [self waitForExpectationsWithCommonTimeout];
}

- (void)test23AnimatedImageViewCategoryProgressive {
    XCTestExpectation *expectation = [self expectationWithDescription:@"test TMSDAnimatedImageView view category progressive"];
    TMSDAnimatedImageView *imageView = [TMSDAnimatedImageView new];
    NSURL *testURL = [NSURL URLWithString:kTestGIFURL];
    [TMSDImageCache.sharedImageCache removeImageFromMemoryForKey:testURL.absoluteString];
    [TMSDImageCache.sharedImageCache removeImageFromDiskForKey:testURL.absoluteString];
    [imageView tmsd_setImageWithURL:testURL placeholderImage:nil options:TMSDWebImageProgressiveLoad progress:^(NSInteger receivedSize, NSInteger expectedSize, NSURL * _Nullable targetURL) {
        dispatch_async(dispatch_get_main_queue(), ^{
            UIImage *image = imageView.image;
            // Progressive image may be nil when download data is not enough
            if (image) {
                expect(image.tmsd_isIncremental).beTruthy();
                expect([image.class conformsToProtocol:@protocol(TMSDAnimatedImage)]).beTruthy();
                BOOL isProgressive = imageView.isProgressive;
                expect(isProgressive).equal(YES);
            }
        });
    } completed:^(UIImage * _Nullable image, NSError * _Nullable error, TMSDImageCacheType cacheType, NSURL * _Nullable imageURL) {
        expect(error).to.beNil();
        expect(image).notTo.beNil();
        expect([image isKindOfClass:[TMSDAnimatedImage class]]).beTruthy();
        expect(cacheType).equal(TMSDImageCacheTypeNone);
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:kAsyncTestTimeout * 2 handler:nil];
}

- (void)test24AnimatedImageViewCategoryDiskCache {
    XCTestExpectation *expectation = [self expectationWithDescription:@"test TMSDAnimatedImageView view category disk cache"];
    TMSDAnimatedImageView *imageView = [TMSDAnimatedImageView new];
    NSURL *testURL = [NSURL URLWithString:kTestGIFURL];
    [TMSDImageCache.sharedImageCache removeImageFromMemoryForKey:testURL.absoluteString];
    [imageView tmsd_setImageWithURL:testURL placeholderImage:nil completed:^(UIImage * _Nullable image, NSError * _Nullable error, TMSDImageCacheType cacheType, NSURL * _Nullable imageURL) {
        expect(error).to.beNil();
        expect(image).notTo.beNil();
        expect(cacheType).equal(TMSDImageCacheTypeDisk);
        expect([image isKindOfClass:[TMSDAnimatedImage class]]).beTruthy();
        [expectation fulfill];
    }];
    [self waitForExpectationsWithCommonTimeout];
}

- (void)test25AnimatedImageStopAnimatingNormal {
    XCTestExpectation *expectation = [self expectationWithDescription:@"test TMSDAnimatedImageView stopAnimating normal behavior"];
    
    TMSDAnimatedImageView *imageView = [TMSDAnimatedImageView new];
    
#if TMSD_UIKIT
    [self.window addSubview:imageView];
#else
    [self.window.contentView addSubview:imageView];
#endif
    // This APNG duration is 2s
    TMSDAnimatedImage *image = [TMSDAnimatedImage imageWithData:[self testAPNGPData]];
    imageView.image = image;
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        // 0.5s is not finished, frame index should not be 0
        expect(imageView.player.frameBuffer.count).beGreaterThan(0);
        expect(imageView.currentFrameIndex).beGreaterThan(0);
    });
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
#if TMSD_UIKIT
        [imageView stopAnimating];
#else
        imageView.animates = NO;
#endif
        expect(imageView.player.frameBuffer.count).beGreaterThan(0);
        expect(imageView.currentFrameIndex).beGreaterThan(0);
        
        [imageView removeFromSuperview];
        [expectation fulfill];
    });
    
    [self waitForExpectationsWithCommonTimeout];
}

- (void)test26AnimatedImageStopAnimatingClearBuffer {
    XCTestExpectation *expectation = [self expectationWithDescription:@"test TMSDAnimatedImageView stopAnimating clear buffer when stopped"];
    
    TMSDAnimatedImageView *imageView = [TMSDAnimatedImageView new];
    imageView.clearBufferWhenStopped = YES;
    imageView.resetFrameIndexWhenStopped = YES;
    
#if TMSD_UIKIT
    [self.window addSubview:imageView];
#else
    [self.window.contentView addSubview:imageView];
#endif
    // This APNG duration is 2s
    TMSDAnimatedImage *image = [TMSDAnimatedImage imageWithData:[self testAPNGPData]];
    imageView.image = image;
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        // 0.5s is not finished, frame index should not be 0
        expect(imageView.player.frameBuffer.count).beGreaterThan(0);
        expect(imageView.currentFrameIndex).beGreaterThan(0);
    });
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
#if TMSD_UIKIT
        [imageView stopAnimating];
#else
        imageView.animates = NO;
#endif
        expect(imageView.player.frameBuffer.count).equal(0);
        
        [imageView removeFromSuperview];
        [expectation fulfill];
    });
    
    [self waitForExpectationsWithCommonTimeout];
}

- (void)test27AnimatedImageProgressiveAnimation {
    XCTestExpectation *expectation = [self expectationWithDescription:@"test TMSDAnimatedImageView progressive animation rendering"];
    
    // Simulate progressive download
    NSData *fullData = [self testAPNGPData];
    NSUInteger length = fullData.length;
    
    TMSDAnimatedImageView *imageView = [TMSDAnimatedImageView new];
#if TMSD_UIKIT
    [self.window addSubview:imageView];
#else
    [self.window.contentView addSubview:imageView];
#endif
    
    __block NSUInteger previousFrameIndex = 0;
    @weakify(imageView);
    // Observe to check rendering behavior using frame index
    [self.KVOController observe:imageView keyPath:NSStringFromSelector(@selector(currentFrameIndex)) options:NSKeyValueObservingOptionNew block:^(id  _Nullable observer, id  _Nonnull object, NSDictionary<NSString *,id> * _Nonnull change) {
        @strongify(imageView);
        NSUInteger currentFrameIndex = [change[NSKeyValueChangeNewKey] unsignedIntegerValue];
        printf("Animation Frame Index: %lu\n", (unsigned long)currentFrameIndex);
        
        // The last time should not be progressive
        if (currentFrameIndex == 0 && !imageView.isProgressive) {
            [self.KVOController unobserve:imageView];
            [expectation fulfill];
        } else {
            // Each progressive rendering should render new frame index, no backward and should stop at last frame index
            expect(currentFrameIndex - previousFrameIndex).beGreaterThanOrEqualTo(0);
            previousFrameIndex = currentFrameIndex;
        }
    }];
    
    TMSDImageAPNGCoder *coder = [[TMSDImageAPNGCoder alloc] initIncrementalWithOptions:nil];
    // Setup Data
    NSData *setupData = [fullData subdataWithRange:NSMakeRange(0, length / 3.0)];
    [coder updateIncrementalData:setupData finished:NO];
    imageView.shouldIncrementalLoad = YES;
    __block TMSDAnimatedImage *progressiveImage = [[TMSDAnimatedImage alloc] initWithAnimatedCoder:coder scale:1];
    progressiveImage.tmsd_isIncremental = YES;
    imageView.image = progressiveImage;
    expect(imageView.isProgressive).beTruthy();
    
    __block NSUInteger partialFrameCount;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        // Partial Data
        NSData *partialData = [fullData subdataWithRange:NSMakeRange(0, length * 2.0 / 3.0)];
        [coder updateIncrementalData:partialData finished:NO];
        partialFrameCount = [coder animatedImageFrameCount];
        expect(partialFrameCount).beGreaterThan(1);
        progressiveImage = [[TMSDAnimatedImage alloc] initWithAnimatedCoder:coder scale:1];
        progressiveImage.tmsd_isIncremental = YES;
        imageView.image = progressiveImage;
        expect(imageView.isProgressive).beTruthy();
    });
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(4 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        // Full Data
        [coder updateIncrementalData:fullData finished:YES];
        progressiveImage = [[TMSDAnimatedImage alloc] initWithAnimatedCoder:coder scale:1];
        progressiveImage.tmsd_isIncremental = NO;
        imageView.image = progressiveImage;
        NSUInteger fullFrameCount = [coder animatedImageFrameCount];
        expect(fullFrameCount).beGreaterThan(partialFrameCount);
        expect(imageView.isProgressive).beFalsy();
    });
    
    [self waitForExpectationsWithCommonTimeout];
}

- (void)test28AnimatedImageAutoPlayAnimatedImage {
    XCTestExpectation *expectation = [self expectationWithDescription:@"test TMSDAnimatedImageView AutoPlayAnimatedImage behavior"];
    
    TMSDAnimatedImageView *imageView = [TMSDAnimatedImageView new];
    imageView.autoPlayAnimatedImage = NO;
    
#if TMSD_UIKIT
    [self.window addSubview:imageView];
#else
    [self.window.contentView addSubview:imageView];
#endif
    // This APNG duration is 2s
    TMSDAnimatedImage *image = [TMSDAnimatedImage imageWithData:[self testAPNGPData]];
    imageView.image = image;

    #if TMSD_UIKIT
        expect(imageView.animating).equal(NO);
    #else
        expect(imageView.animates).equal(NO);
    #endif
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        #if TMSD_UIKIT
            expect(imageView.animating).equal(NO);
        #else
            expect(imageView.animates).equal(NO);
        #endif
        
        #if TMSD_UIKIT
            [imageView startAnimating];
        #else
            imageView.animates = YES;
        #endif
    });
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        #if TMSD_UIKIT
            expect(imageView.animating).equal(YES);
        #else
            expect(imageView.animates).equal(YES);
        #endif
        
        #if TMSD_UIKIT
            [imageView stopAnimating];
        #else
            imageView.animates = NO;
        #endif
        
        [imageView removeFromSuperview];
        [expectation fulfill];
    });
    
    [self waitForExpectationsWithCommonTimeout];
}

- (void)test29AnimatedImageSeekFrame {
    XCTestExpectation *expectation = [self expectationWithDescription:@"test TMSDAnimatedImageView stopAnimating normal behavior"];
    
    TMSDAnimatedImageView *imageView = [TMSDAnimatedImageView new];
    
#if TMSD_UIKIT
    [self.window addSubview:imageView];
#else
    [self.window.contentView addSubview:imageView];
#endif
    // seeking through local image should return non-null images
    TMSDAnimatedImage *image = [TMSDAnimatedImage imageWithData:[self testAPNGPData]];
    imageView.autoPlayAnimatedImage = NO;
    imageView.image = image;
    
    __weak TMSDAnimatedImagePlayer *player = imageView.player;

    __block NSUInteger i = 0;
    [player setAnimationFrameHandler:^(NSUInteger index, UIImage * _Nonnull frame) {
        expect(index).equal(i);
        expect(frame).notTo.beNil();
        i++;
        if (i < player.totalFrameCount) {
            [player seekToFrameAtIndex:i loopCount:0];
        } else {
            [expectation fulfill];
        }
    }];
    [player seekToFrameAtIndex:i loopCount:0];
    
    [self waitForExpectationsWithCommonTimeout];
}

- (void)test30AnimatedImageCoderPriority {
    [TMSDImageCodersManager.sharedManager addCoder:TMSDImageAPNGTestCoder.sharedCoder];
    [TMSDAnimatedImage imageWithData:[self testAPNGPData]];
    expect(TMSDImageAPNGTestCoder.isCalled).equal(YES);
}

#if TMSD_UIKIT
- (void)test31AnimatedImageViewSetAnimationImages {
    TMSDAnimatedImageView *imageView = [TMSDAnimatedImageView new];
    UIImage *image = [[UIImage alloc] initWithData:[self testJPEGData]];
    imageView.animationImages = @[image];
    expect(imageView.animationImages).notTo.beNil();
}

- (void)test32AnimatedImageViewNotStopPlayingAnimationImagesWhenHidden {
    TMSDAnimatedImageView *imageView = [TMSDAnimatedImageView new];
    [self.window addSubview:imageView];
    UIImage *image = [[UIImage alloc] initWithData:[self testJPEGData]];
    imageView.animationImages = @[image];
    [imageView startAnimating];
    expect(imageView.animating).beTruthy();
    imageView.hidden = YES;
    expect(imageView.animating).beTruthy();
}
#endif

- (void)test33AnimatedImagePlaybackModeReverse {
    XCTestExpectation *expectation = [self expectationWithDescription:@"test TMSDAnimatedImageView playback reverse mode"];
    
    TMSDAnimatedImageView *imageView = [TMSDAnimatedImageView new];
    
#if TMSD_UIKIT
    [self.window addSubview:imageView];
#else
    [self.window.contentView addSubview:imageView];
#endif
    
    TMSDAnimatedImage *image = [TMSDAnimatedImage imageWithData:[self testAPNGPData]];
    imageView.autoPlayAnimatedImage = NO;
    imageView.image = image;
    
    __weak TMSDAnimatedImagePlayer *player = imageView.player;
    player.playbackMode = TMSDAnimatedImagePlaybackModeReverse;

    __block NSInteger i = player.totalFrameCount - 1;
    __weak typeof(imageView) wimageView = imageView;
    [player setAnimationFrameHandler:^(NSUInteger index, UIImage * _Nonnull frame) {
        expect(index).equal(i);
        expect(frame).notTo.beNil();
        if (index == 0) {
            [expectation fulfill];
            // Stop Animation to avoid extra callback
            [wimageView.player stopPlaying];
            [wimageView removeFromSuperview];
            return;
        }
        i--;
    }];
    
    [player startPlaying];
    
    [self waitForExpectationsWithTimeout:15 handler:nil];
}

- (void)test34AnimatedImagePlaybackModeBounce {
    XCTestExpectation *expectation = [self expectationWithDescription:@"test TMSDAnimatedImageView playback bounce mode"];
    
    TMSDAnimatedImageView *imageView = [TMSDAnimatedImageView new];
    
#if TMSD_UIKIT
    [self.window addSubview:imageView];
#else
    [self.window.contentView addSubview:imageView];
#endif
    
    TMSDAnimatedImage *image = [TMSDAnimatedImage imageWithData:[self testAPNGPData]];
    imageView.autoPlayAnimatedImage = NO;
    imageView.image = image;
    
    __weak TMSDAnimatedImagePlayer *player = imageView.player;
    player.playbackMode = TMSDAnimatedImagePlaybackModeBounce;

    __block NSInteger i = 0;
    __block BOOL flag = false;
    __block NSUInteger cnt = 0;
    __weak typeof(imageView) wimageView = imageView;
    [player setAnimationFrameHandler:^(NSUInteger index, UIImage * _Nonnull frame) {
        expect(index).equal(i);
        expect(frame).notTo.beNil();
        
        if (index >= player.totalFrameCount - 1) {
            cnt++;
            flag = true;
        } else if (cnt != 0 && index == 0) {
            cnt++;
            flag = false;
        }
        
        if (!flag) {
            i++;
        } else {
            i--;
        }

        if (cnt >= 2) {
            [expectation fulfill];
            // Stop Animation to avoid extra callback
            [wimageView.player stopPlaying];
            [wimageView removeFromSuperview];
        }
    }];
    
    [player startPlaying];
    
    [self waitForExpectationsWithTimeout:15 handler:nil];
}

- (void)test35AnimatedImagePlaybackModeReversedBounce {
    XCTestExpectation *expectation = [self expectationWithDescription:@"test TMSDAnimatedImageView playback reverse bounce mode"];
    
    TMSDAnimatedImageView *imageView = [TMSDAnimatedImageView new];
    
#if TMSD_UIKIT
    [self.window addSubview:imageView];
#else
    [self.window.contentView addSubview:imageView];
#endif
    
    TMSDAnimatedImage *image = [TMSDAnimatedImage imageWithData:[self testAPNGPData]];
    imageView.autoPlayAnimatedImage = NO;
    imageView.image = image;
    
    __weak TMSDAnimatedImagePlayer *player = imageView.player;
    player.playbackMode = TMSDAnimatedImagePlaybackModeReversedBounce;

    __block NSInteger i = player.totalFrameCount - 1;
    __block BOOL flag = false;
    __block NSUInteger cnt = 0;
    __weak typeof(imageView) wimageView = imageView;
    [player setAnimationFrameHandler:^(NSUInteger index, UIImage * _Nonnull frame) {
        expect(index).equal(i);
        expect(frame).notTo.beNil();
        
        if (cnt != 0 && index >= player.totalFrameCount - 1) {
            cnt++;
            flag = false;
        } else if (index == 0) {
            cnt++;
            flag = true;
        }
        
        if (flag) {
            i++;
        } else {
            i--;
        }

        if (cnt >= 2) {
            [expectation fulfill];
            // Stop Animation to avoid extra callback
            [wimageView.player stopPlaying];
            [wimageView removeFromSuperview];
        }
    }];
    [player startPlaying];
    
    [self waitForExpectationsWithTimeout:15 handler:nil];
}

- (void)test36AnimatedImageMemoryCost {
    if (@available(iOS 14, tvOS 14, macOS 11, watchOS 7, *)) {
#if TMSD_TV
        /// TV OS does not support ImageIO's webp.
        [[TMSDImageCodersManager sharedManager] addCoder:[TMSDImageWebPCoder sharedCoder]];
#else
        [[TMSDImageCodersManager sharedManager] addCoder:[TMSDImageAWebPCoder sharedCoder]];
#endif
        UIImage *image = [UIImage tmsd_imageWithData:[NSData dataWithContentsOfFile:[self testMemotyCostImagePath]]];
        NSUInteger cost = [image tmsd_memoryCost];
#if TMSD_UIKIT
        expect(image.images.count).equal(5333);
#endif
        expect(image.tmsd_imageFrameCount).equal(16);
        expect(image.scale).equal(1);
#if TMSD_MAC
        /// Frame count is 1 in mac.
        expect(cost).equal(image.size.width * image.size.height * 4);
#else
        expect(cost).equal(16 * image.size.width * image.size.height * 4);
#endif
        [[TMSDImageCodersManager sharedManager] removeCoder:[TMSDImageAWebPCoder sharedCoder]];
    }
}

#pragma mark - Helper
- (UIWindow *)window {
    if (!_window) {
        UIScreen *mainScreen = [UIScreen mainScreen];
#if TMSD_UIKIT
        _window = [[UIWindow alloc] initWithFrame:mainScreen.bounds];
#else
        _window = [[NSWindow alloc] initWithContentRect:mainScreen.frame styleMask:0 backing:NSBackingStoreBuffered defer:NO screen:mainScreen];
#endif
    }
    return _window;
}

- (NSString *)testGIFPath {
    NSBundle *testBundle = [NSBundle bundleForClass:[self class]];
    NSString *testPath = [testBundle pathForResource:@"TestImage" ofType:@"gif"];
    return testPath;
}

- (NSData *)testGIFData {
    NSData *testData = [NSData dataWithContentsOfFile:[self testGIFPath]];
    return testData;
}

- (NSString *)testAPNGPPath {
    NSBundle *testBundle = [NSBundle bundleForClass:[self class]];
    NSString *testPath = [testBundle pathForResource:@"TestImageAnimated" ofType:@"apng"];
    return testPath;
}

- (NSString *)testMemotyCostImagePath {
    NSBundle *testBundle = [NSBundle bundleForClass:[self class]];
    NSString *testPath = [testBundle pathForResource:@"TestAnimatedImageMemory" ofType:@"webp"];
    return testPath;
}

- (NSData *)testAPNGPData {
    return [NSData dataWithContentsOfFile:[self testAPNGPPath]];
}

- (NSString *)testJPEGPath {
    NSBundle *testBundle = [NSBundle bundleForClass:[self class]];
    NSString *testPath = [testBundle pathForResource:@"TestImage" ofType:@"jpg"];
    return testPath;
}

- (NSData *)testJPEGData {
    NSData *testData = [NSData dataWithContentsOfFile:[self testJPEGPath]];
    return testData;
}

@end
