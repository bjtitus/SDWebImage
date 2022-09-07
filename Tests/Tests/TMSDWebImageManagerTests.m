/*
 * This file is part of the TMSDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import <TMSDWebImage/TMSDTestCase.h>
#import <TMSDWebImage/TMSDWebImageTestTransformer.h>
#import <TMSDWebImage/TMSDWebImageTestCache.h>
#import <TMSDWebImage/TMSDWebImageTestLoader.h>

// Keep strong references for object
@interface TMSDObjectContainer<ObjectType> : NSObject
@property (nonatomic, strong, readwrite) ObjectType object;
@end

@implementation TMSDObjectContainer
@end

@interface TMSDWebImageManagerTests : TMSDTestCase

@end

@implementation TMSDWebImageManagerTests

- (void)test01ThatSharedManagerIsNotEqualToInitManager {
    TMSDWebImageManager *manager = [[TMSDWebImageManager alloc] init];
    expect(manager).toNot.equal([TMSDWebImageManager sharedManager]);
}

- (void)test02ThatDownloadInvokesCompletionBlockWithCorrectParamsAsync {
    __block XCTestExpectation *expectation = [self expectationWithDescription:@"Image download completes"];

    NSURL *originalImageURL = [NSURL URLWithString:kTestJPEGURL];
    
    [TMSDImageCache.sharedImageCache removeImageFromMemoryForKey:kTestJPEGURL];
    [TMSDImageCache.sharedImageCache removeImageFromDiskForKey:kTestJPEGURL];
    TMSDObjectContainer<TMSDWebImageCombinedOperation *> *container = [TMSDObjectContainer new];
    container.object = [[TMSDWebImageManager sharedManager] loadImageWithURL:originalImageURL
                                                                   options:0
                                                                  progress:nil
                                                                 completed:^(UIImage *image, NSData *data, NSError *error, TMSDImageCacheType cacheType, BOOL finished, NSURL *imageURL) {
        expect(image).toNot.beNil();
        expect(error).to.beNil();
        expect(originalImageURL).to.equal(imageURL);
        
        // When download, the cache operation will reset to nil since it's always finished
        TMSDWebImageCombinedOperation *operation = container.object;
        expect(container).notTo.beNil();
        expect(operation.cacheOperation).beNil();
        expect(operation.loaderOperation).notTo.beNil();
        container.object = nil;
        
        [expectation fulfill];
        expectation = nil;
    }];
    expect([[TMSDWebImageManager sharedManager] isRunning]).to.equal(YES);

    [self waitForExpectationsWithTimeout:kAsyncTestTimeout * 2 handler:nil];
}

- (void)test03ThatDownloadWithIncorrectURLInvokesCompletionBlockWithAnErrorAsync {
    __block XCTestExpectation *expectation = [self expectationWithDescription:@"Image download completes"];

    NSURL *originalImageURL = [NSURL URLWithString:@"http://static2.dmcdn.net/static/video/656/177/44771656:jpeg_preview_small.png"];
    
    [[TMSDWebImageManager sharedManager] loadImageWithURL:originalImageURL
                                                options:0
                                               progress:nil
                                              completed:^(UIImage *image, NSData *data, NSError *error, TMSDImageCacheType cacheType, BOOL finished, NSURL *imageURL) {
        expect(image).to.beNil();
        expect(error).toNot.beNil();
        expect(originalImageURL).to.equal(imageURL);
        
        [expectation fulfill];
        expectation = nil;
    }];
    
    [self waitForExpectationsWithCommonTimeout];
}

- (void)test06CancellAll {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Cancel should callback with error"];
    
    // need a bigger image here, that is why we don't use kTestJPEGURL
    // if the image is too small, it will get downloaded before we can cancel :)
    NSURL *url = [NSURL URLWithString:@"https://raw.githubusercontent.com/liyong03/YLGIFImage/master/YLGIFImageDemo/YLGIFImageDemo/joy.gif"];
    [[TMSDWebImageManager sharedManager] loadImageWithURL:url options:0 progress:nil completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, TMSDImageCacheType cacheType, BOOL finished, NSURL * _Nullable imageURL) {
        expect(error).notTo.beNil();
        expect(error.code).equal(TMSDWebImageErrorCancelled);
    }];
    
    [[TMSDWebImageManager sharedManager] cancelAll];
    
    // doesn't cancel immediately - since it uses dispatch async
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, kMinDelayNanosecond), dispatch_get_main_queue(), ^{
        expect([[TMSDWebImageManager sharedManager] isRunning]).to.equal(NO);
        [expectation fulfill];
    });
    
    [self waitForExpectationsWithTimeout:kAsyncTestTimeout * 2 handler:nil];
}

- (void)test07ThatLoadImageWithSDWebImageRefreshCachedWorks {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Image download twice with TMSDWebImageRefresh failed"];
    NSURL *originalImageURL = [NSURL URLWithString:@"http://via.placeholder.com/10x10.png"];
    __block BOOL firstCompletion = NO;
    [[TMSDWebImageManager sharedManager] loadImageWithURL:originalImageURL options:TMSDWebImageRefreshCached progress:nil completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, TMSDImageCacheType cacheType, BOOL finished, NSURL * _Nullable imageURL) {
        expect(image).toNot.beNil();
        expect(error).to.beNil();
        // #1993, load image with TMSDWebImageRefreshCached twice should not fail if the first time success.
        
        // Because we call completion before remove the operation from queue, so need a dispatch to avoid get the same operation again. Attention this trap.
        // One way to solve this is use another `NSURL instance` because we use `NSURL` as key but not `NSString`. However, this is implementation detail and no guarantee in the future.
        dispatch_async(dispatch_get_main_queue(), ^{
            NSURL *newImageURL = [NSURL URLWithString:@"http://via.placeholder.com/10x10.png"];
            [[TMSDWebImageManager sharedManager] loadImageWithURL:newImageURL options:TMSDWebImageRefreshCached progress:nil completed:^(UIImage * _Nullable image2, NSData * _Nullable data2, NSError * _Nullable error2, TMSDImageCacheType cacheType2, BOOL finished2, NSURL * _Nullable imageURL2) {
                expect(image2).toNot.beNil();
                expect(error2).to.beNil();
                if (!firstCompletion) {
                    firstCompletion = YES;
                    [expectation fulfill];
                }
            }];
        });
    }];
    
    [self waitForExpectationsWithTimeout:kAsyncTestTimeout * 2 handler:nil];
}

- (void)test08ThatImageTransformerWork {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Image transformer work"];
    NSURL *url = [NSURL URLWithString:kTestJPEGURL];
    TMSDWebImageTestTransformer *transformer = [[TMSDWebImageTestTransformer alloc] init];
    
    transformer.testImage = [[UIImage alloc] initWithContentsOfFile:[self testJPEGPath]];
    TMSDWebImageManager *manager = [[TMSDWebImageManager alloc] initWithCache:[TMSDImageCache sharedImageCache] loader:[TMSDWebImageDownloader sharedDownloader]];
    manager.transformer = transformer;
    [[TMSDImageCache sharedImageCache] removeImageForKey:kTestJPEGURL withCompletion:^{
        [manager loadImageWithURL:url options:TMSDWebImageTransformAnimatedImage | TMSDWebImageTransformVectorImage progress:nil completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, TMSDImageCacheType cacheType, BOOL finished, NSURL * _Nullable imageURL) {
            expect(image).equal(transformer.testImage);
            [expectation fulfill];
        }];
    }];
    
    [self waitForExpectationsWithCommonTimeout];
}

- (void)test09ThatCacheKeyFilterWork {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Cache key filter work"];
    NSURL *url = [NSURL URLWithString:kTestJPEGURL];
    
    NSString *cacheKey = @"kTestJPEGURL";
    TMSDWebImageCacheKeyFilter *cacheKeyFilter = [TMSDWebImageCacheKeyFilter cacheKeyFilterWithBlock:^NSString * _Nullable(NSURL * _Nonnull imageURL) {
        if ([url isEqual:imageURL]) {
            return cacheKey;
        } else {
            return url.absoluteString;
        }
    }];
    
    TMSDWebImageManager *manager = [[TMSDWebImageManager alloc] initWithCache:[TMSDImageCache sharedImageCache] loader:[TMSDWebImageDownloader sharedDownloader]];
    manager.cacheKeyFilter = cacheKeyFilter;
    // Check download and retrieve custom cache key
    [manager loadImageWithURL:url options:0 context:@{TMSDWebImageContextStoreCacheType : @(TMSDImageCacheTypeMemory)} progress:nil completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, TMSDImageCacheType cacheType, BOOL finished, NSURL * _Nullable imageURL) {
        expect(cacheType).equal(TMSDImageCacheTypeNone);
        
        // Check memory cache exist
        [manager.imageCache containsImageForKey:cacheKey cacheType:TMSDImageCacheTypeMemory completion:^(TMSDImageCacheType containsCacheType) {
            expect(containsCacheType).equal(TMSDImageCacheTypeMemory);
            
            [expectation fulfill];
        }];
    }];
    
    [self waitForExpectationsWithCommonTimeout];
}

- (void)test10ThatCacheSerializerWork {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Cache serializer work"];
    NSURL *url = [NSURL URLWithString:kTestJPEGURL];
    __block NSData *imageData;
    
    TMSDWebImageCacheSerializer *cacheSerializer = [TMSDWebImageCacheSerializer cacheSerializerWithBlock:^NSData * _Nullable(UIImage * _Nonnull image, NSData * _Nullable data, NSURL * _Nullable imageURL) {
        imageData = [image tmsd_imageDataAsFormat:TMSDImageFormatPNG];
        return imageData;
    }];
    
    TMSDWebImageManager *manager = [[TMSDWebImageManager alloc] initWithCache:[TMSDImageCache sharedImageCache] loader:[TMSDWebImageDownloader sharedDownloader]];
    manager.cacheSerializer = cacheSerializer;
    // Check download and store custom disk data
    [[TMSDImageCache sharedImageCache] removeImageForKey:kTestJPEGURL withCompletion:^{
        [manager loadImageWithURL:url options:0 progress:nil completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, TMSDImageCacheType cacheType, BOOL finished, NSURL * _Nullable imageURL) {
            // Dispatch to let store disk finish
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, kMinDelayNanosecond), dispatch_get_main_queue(), ^{
                NSData *diskImageData = [[TMSDImageCache sharedImageCache] diskImageDataForKey:kTestJPEGURL];
                expect(diskImageData).equal(imageData); // disk data equal to serializer data
                
                [expectation fulfill];
            });
        }];
    }];
    
    [self waitForExpectationsWithCommonTimeout];
}

- (void)test11ThatOptionsProcessorWork {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Options processor work"];
    __block BOOL optionsProcessorCalled = NO;
    
    TMSDWebImageManager *manager = [[TMSDWebImageManager alloc] initWithCache:[TMSDImageCache sharedImageCache] loader:[TMSDWebImageDownloader sharedDownloader]];
    manager.optionsProcessor = [TMSDWebImageOptionsProcessor optionsProcessorWithBlock:^TMSDWebImageOptionsResult * _Nullable(NSURL * _Nonnull url, TMSDWebImageOptions options, TMSDWebImageContext * _Nullable context) {
        if ([url.absoluteString isEqualToString:kTestPNGURL]) {
            optionsProcessorCalled = YES;
            return [[TMSDWebImageOptionsResult alloc] initWithOptions:0 context:@{TMSDWebImageContextImageScaleFactor : @(3)}];
        } else {
            return nil;
        }
    }];
    
    NSURL *url = [NSURL URLWithString:kTestPNGURL];
    [[TMSDImageCache sharedImageCache] removeImageForKey:kTestPNGURL withCompletion:^{
        [manager loadImageWithURL:url options:0 progress:nil completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, TMSDImageCacheType cacheType, BOOL finished, NSURL * _Nullable imageURL) {
            expect(image.scale).equal(3);
            expect(optionsProcessorCalled).beTruthy();
            
            [expectation fulfill];
        }];
    }];
    
    [self waitForExpectationsWithCommonTimeout];
}

- (void)test12ThatStoreCacheTypeWork {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Image store cache type (including transformer) work"];
    
    // Use a fresh manager && cache to avoid get effected by other test cases
    TMSDImageCache *cache = [[TMSDImageCache alloc] initWithNamespace:@"TMSDWebImageStoreCacheType"];
    [cache clearDiskOnCompletion:nil];
    TMSDWebImageManager *manager = [[TMSDWebImageManager alloc] initWithCache:cache loader:TMSDWebImageDownloader.sharedDownloader];
    TMSDWebImageTestTransformer *transformer = [[TMSDWebImageTestTransformer alloc] init];
    transformer.testImage = [[UIImage alloc] initWithContentsOfFile:[self testJPEGPath]];
    manager.transformer = transformer;
    
    // test: original image -> disk only, transformed image -> memory only
    TMSDWebImageContext *context = @{TMSDWebImageContextOriginalStoreCacheType : @(TMSDImageCacheTypeDisk), TMSDWebImageContextStoreCacheType : @(TMSDImageCacheTypeMemory)};
    NSURL *url = [NSURL URLWithString:kTestAPNGPURL];
    NSString *originalKey = [manager cacheKeyForURL:url];
    NSString *transformedKey = [manager cacheKeyForURL:url context:context];
    
    [manager loadImageWithURL:url options:TMSDWebImageTransformAnimatedImage context:context progress:nil completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, TMSDImageCacheType cacheType, BOOL finished, NSURL * _Nullable imageURL) {
        expect(image).equal(transformer.testImage);
        // the transformed image should not inherite any attribute from original one
        expect(image.tmsd_imageFormat).equal(TMSDImageFormatJPEG);
        expect(image.tmsd_isAnimated).beFalsy();
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2*kMinDelayNanosecond), dispatch_get_main_queue(), ^{
            // original -> disk only
            UIImage *originalImage = [cache imageFromMemoryCacheForKey:originalKey];
            expect(originalImage).beNil();
            NSData *originalData = [cache diskImageDataForKey:originalKey];
            expect(originalData).notTo.beNil();
            originalImage = [UIImage tmsd_imageWithData:originalData];
            expect(originalImage).notTo.beNil();
            expect(originalImage.tmsd_imageFormat).equal(TMSDImageFormatPNG);
            expect(originalImage.tmsd_isAnimated).beTruthy();
            // transformed -> memory only
            [manager.imageCache containsImageForKey:transformedKey cacheType:TMSDImageCacheTypeAll completion:^(TMSDImageCacheType transformedCacheType) {
                expect(transformedCacheType).equal(TMSDImageCacheTypeMemory);
                [cache clearDiskOnCompletion:nil];
                [expectation fulfill];
            }];
        });
    }];
    
    [self waitForExpectationsWithCommonTimeout];
}

- (void)test13ThatScaleDownLargeImageUseThumbnailDecoding {
    XCTestExpectation *expectation = [self expectationWithDescription:@"TMSDWebImageScaleDownLargeImages should translate to thumbnail decoding"];
    NSURL *originalImageURL = [NSURL URLWithString:@"http://via.placeholder.com/3999x3999.png"]; // Max size for this API
    NSUInteger defaultLimitBytes = TMSDImageCoderHelper.defaultScaleDownLimitBytes;
    TMSDImageCoderHelper.defaultScaleDownLimitBytes = 1000 * 1000 * 4; // Limit 1000x1000 pixel
    // From v5.5.0, the `TMSDWebImageScaleDownLargeImages` translate to `TMSDWebImageContextImageThumbnailPixelSize`, and works for progressive loading
    [TMSDImageCache.sharedImageCache removeImageFromDiskForKey:originalImageURL.absoluteString];
    [TMSDWebImageManager.sharedManager loadImageWithURL:originalImageURL options:TMSDWebImageScaleDownLargeImages | TMSDWebImageProgressiveLoad progress:nil completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, TMSDImageCacheType cacheType, BOOL finished, NSURL * _Nullable imageURL) {
        expect(image).notTo.beNil();
        expect(image.size).equal(CGSizeMake(1000, 1000));
        if (finished) {
            expect(image.tmsd_isIncremental).beFalsy();
            [expectation fulfill];
        } else {
            expect(image.tmsd_isIncremental).beTruthy();
        }
    }];
    
    [self waitForExpectationsWithCommonTimeoutUsingHandler:^(NSError * _Nullable error) {
        TMSDImageCoderHelper.defaultScaleDownLimitBytes = defaultLimitBytes;
    }];
}

- (void)test13ThatScaleDownLargeImageEXIFOrientationImage {
    XCTestExpectation *expectation = [self expectationWithDescription:@"TMSDWebImageScaleDownLargeImages works on EXIF orientation image"];
    NSURL *originalImageURL = [NSURL URLWithString:@"https://raw.githubusercontent.com/recurser/exif-orientation-examples/master/Landscape_2.jpg"];
    [TMSDWebImageManager.sharedManager loadImageWithURL:originalImageURL options:TMSDWebImageScaleDownLargeImages | TMSDWebImageAvoidDecodeImage progress:nil completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, TMSDImageCacheType cacheType, BOOL finished, NSURL * _Nullable imageURL) {
        expect(image).notTo.beNil();
#if TMSD_UIKIT
        UIImageOrientation orientation = [TMSDImageCoderHelper imageOrientationFromEXIFOrientation:kCGImagePropertyOrientationUpMirrored];
        expect(image.imageOrientation).equal(orientation);
#endif
        if (finished) {
            expect(image.tmsd_isIncremental).beFalsy();
            [expectation fulfill];
        } else {
            expect(image.tmsd_isIncremental).beTruthy();
        }
    }];
    
    [self waitForExpectationsWithCommonTimeout];
}

- (void)test14ThatCustomCacheAndLoaderWorks {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Custom Cache and Loader during manger query"];
    NSURL *url = [NSURL URLWithString:@"http://via.placeholder.com/100x100.png"];
    TMSDWebImageContext *context = @{
        TMSDWebImageContextImageCache : TMSDWebImageTestCache.sharedCache,
        TMSDWebImageContextImageLoader : TMSDWebImageTestLoader.sharedLoader
    };
    [TMSDWebImageTestCache.sharedCache clearWithCacheType:TMSDImageCacheTypeAll completion:nil];
    [TMSDWebImageManager.sharedManager loadImageWithURL:url options:TMSDWebImageWaitStoreCache context:context progress:nil completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, TMSDImageCacheType cacheType, BOOL finished, NSURL * _Nullable imageURL) {
        expect(image).notTo.beNil();
        expect(image.size.width).equal(100);
        expect(image.size.height).equal(100);
        expect(data).notTo.beNil();
        NSString *cacheKey = [TMSDWebImageManager.sharedManager cacheKeyForURL:imageURL];
        // Check Disk Cache (TMSDWebImageWaitStoreCache behavior)
        [TMSDWebImageTestCache.sharedCache containsImageForKey:cacheKey cacheType:TMSDImageCacheTypeDisk completion:^(TMSDImageCacheType containsCacheType) {
            expect(containsCacheType).equal(TMSDImageCacheTypeDisk);
            [expectation fulfill];
        }];
    }];
    
    [self waitForExpectationsWithCommonTimeout];
}

- (void)test15ThatQueryCacheTypeWork {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Image query cache type works"];
    NSURL *url = [NSURL URLWithString:@"http://via.placeholder.com/101x101.png"];
    NSString *key = [TMSDWebImageManager.sharedManager cacheKeyForURL:url];
    NSData *testImageData = [NSData dataWithContentsOfFile:[self testJPEGPath]];
    [TMSDImageCache.sharedImageCache storeImageDataToDisk:testImageData forKey:key];
    
    // Query memory first
    [TMSDWebImageManager.sharedManager loadImageWithURL:url options:TMSDWebImageFromCacheOnly context:@{TMSDWebImageContextQueryCacheType : @(TMSDImageCacheTypeMemory)} progress:nil completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, TMSDImageCacheType cacheType, BOOL finished, NSURL * _Nullable imageURL) {
        expect(image).beNil();
        expect(cacheType).equal(TMSDImageCacheTypeNone);
        // Query disk secondly
        [TMSDWebImageManager.sharedManager loadImageWithURL:url options:TMSDWebImageFromCacheOnly context:@{TMSDWebImageContextQueryCacheType : @(TMSDImageCacheTypeDisk)} progress:nil completed:^(UIImage * _Nullable image2, NSData * _Nullable data2, NSError * _Nullable error2, TMSDImageCacheType cacheType2, BOOL finished2, NSURL * _Nullable imageURL2) {
            expect(image2).notTo.beNil();
            expect(cacheType2).equal(TMSDImageCacheTypeDisk);
            [TMSDImageCache.sharedImageCache removeImageFromDiskForKey:key];
            [expectation fulfill];
        }];
    }];
    
    [self waitForExpectationsWithCommonTimeout];
}

- (void)test15ThatOriginalQueryCacheTypeWork {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Image original query cache type with transformer works"];
    NSURL *url = [NSURL URLWithString:@"http://via.placeholder.com/102x102.png"];
    TMSDWebImageTestTransformer *transformer = [[TMSDWebImageTestTransformer alloc] init];
    transformer.testImage = [[UIImage alloc] initWithContentsOfFile:[self testJPEGPath]];
    NSString *originalKey = [TMSDWebImageManager.sharedManager cacheKeyForURL:url];
    NSString *transformedKey = [TMSDWebImageManager.sharedManager cacheKeyForURL:url context:@{TMSDWebImageContextImageTransformer : transformer}];
    
    [[TMSDWebImageManager sharedManager] loadImageWithURL:url options:0 context:@{TMSDWebImageContextImageTransformer : transformer, TMSDWebImageContextOriginalStoreCacheType : @(TMSDImageCacheTypeAll)} progress:nil completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, TMSDImageCacheType cacheType, BOOL finished, NSURL * _Nullable imageURL) {
        // Get the transformed image
        expect(image).equal(transformer.testImage);
        // Now, the original image is stored into memory/disk cache
        UIImage *originalImage = [TMSDImageCache.sharedImageCache imageFromMemoryCacheForKey:originalKey];
        expect(originalImage.size).equal(CGSizeMake(102, 102));
        // Query again with original cache type, which should not trigger any download
        UIImage *transformedImage = [TMSDImageCache.sharedImageCache imageFromMemoryCacheForKey:transformedKey];
        expect(image).equal(transformedImage);
        [TMSDImageCache.sharedImageCache removeImageFromDiskForKey:transformedKey];
        [TMSDImageCache.sharedImageCache removeImageFromMemoryForKey:transformedKey];
        [TMSDWebImageManager.sharedManager loadImageWithURL:url options:TMSDWebImageFromCacheOnly context:@{TMSDWebImageContextImageTransformer : transformer, TMSDWebImageContextOriginalQueryCacheType : @(TMSDImageCacheTypeAll)} progress:nil completed:^(UIImage * _Nullable image2, NSData * _Nullable data2, NSError * _Nullable error2, TMSDImageCacheType cacheType2, BOOL finished2, NSURL * _Nullable imageURL2) {
            // Get the transformed image
            expect(image2).equal(transformer.testImage);
            [TMSDImageCache.sharedImageCache removeImageFromMemoryForKey:originalKey];
            [TMSDImageCache.sharedImageCache removeImageFromDiskForKey:originalKey];
            [expectation fulfill];
        }];
    }];
    
    [self waitForExpectationsWithCommonTimeout];
}

- (void)test16ThatTransformerUseDifferentCacheForOriginalAndTransformedImage {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Image transformer use different cache instance for original image and transformed image works"];
    NSURL *url = [NSURL URLWithString:@"http://via.placeholder.com/103x103.png"];
    TMSDWebImageTestTransformer *transformer = [[TMSDWebImageTestTransformer alloc] init];
    transformer.testImage = [[UIImage alloc] initWithContentsOfFile:[self testJPEGPath]];
    NSString *originalKey = [TMSDWebImageManager.sharedManager cacheKeyForURL:url];
    NSString *transformedKey = [TMSDWebImageManager.sharedManager cacheKeyForURL:url context:@{TMSDWebImageContextImageTransformer : transformer}];
    
    TMSDImageCache *transformerCache = [[TMSDImageCache alloc] initWithNamespace:@"TransformerCache"];
    TMSDImageCache *originalCache = [[TMSDImageCache alloc] initWithNamespace:@"OriginalCache"];
    
    [[TMSDWebImageManager sharedManager] loadImageWithURL:url options:TMSDWebImageWaitStoreCache context:
     @{TMSDWebImageContextImageTransformer : transformer,
       TMSDWebImageContextOriginalImageCache : originalCache,
       TMSDWebImageContextImageCache : transformerCache,
       TMSDWebImageContextOriginalStoreCacheType: @(TMSDImageCacheTypeMemory),
       TMSDWebImageContextStoreCacheType: @(TMSDImageCacheTypeMemory)} progress:nil completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, TMSDImageCacheType cacheType, BOOL finished, NSURL * _Nullable imageURL) {
        // Get the transformed image
        expect(image).equal(transformer.testImage);
        // Now, the original image is stored into originalCache
        UIImage *originalImage = [originalCache imageFromMemoryCacheForKey:originalKey];
        expect(originalImage.size).equal(CGSizeMake(103, 103));
        expect([transformerCache imageFromMemoryCacheForKey:originalKey]).beNil();
        
        // The transformed image is stored into transformerCache
        UIImage *transformedImage = [transformerCache imageFromMemoryCacheForKey:transformedKey];
        expect(image).equal(transformedImage);
        expect([originalCache imageFromMemoryCacheForKey:transformedKey]).beNil();
        
        [originalCache clearWithCacheType:TMSDImageCacheTypeAll completion:nil];
        [transformerCache clearWithCacheType:TMSDImageCacheTypeAll completion:nil];
        
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:kAsyncTestTimeout * 10 handler:nil];
}

- (void)test17ThatThumbnailCacheQueryNotWriteToWrongKey {
    // 1. When query thumbnail decoding for TMSDImageCache, the thumbnailed image should not stored into full size key
    XCTestExpectation *expectation = [self expectationWithDescription:@"Thumbnail for cache should not store the wrong key"];
    
    // 500x500
    CGSize fullSize = CGSizeMake(500, 500);
    TMSDGraphicsImageRenderer *renderer = [[TMSDGraphicsImageRenderer alloc] initWithSize:fullSize];
    UIImage *fullSizeImage = [renderer imageWithActions:^(CGContextRef  _Nonnull context) {
        CGContextSetRGBFillColor(context, 1.0, 0.0, 0.0, 1.0);
        CGContextSetRGBStrokeColor(context, 1.0, 0.0, 0.0, 1.0);
        CGContextFillRect(context, CGRectMake(0, 0, fullSize.width, fullSize.height));
    }];
    expect(fullSizeImage.size).equal(fullSize);
    
    NSString *fullSizeKey = @"kTestRectangle";
    // Disk only
    [TMSDImageCache.sharedImageCache storeImageDataToDisk:fullSizeImage.tmsd_imageData forKey:fullSizeKey];
    
    CGSize thumbnailSize = CGSizeMake(100, 100);
    NSString *thumbnailKey = TMSDThumbnailedKeyForKey(fullSizeKey, thumbnailSize, YES);
    // thumbnail size key miss, full size key hit
    [TMSDImageCache.sharedImageCache queryCacheOperationForKey:fullSizeKey options:0 context:@{TMSDWebImageContextImageThumbnailPixelSize : @(thumbnailSize)} done:^(UIImage * _Nullable image, NSData * _Nullable data, TMSDImageCacheType cacheType) {
        expect(image.size).equal(thumbnailSize);
        expect(cacheType).equal(TMSDImageCacheTypeDisk);
        // Currently, thumbnail decoding does not write back to the original key's memory cache
        // But this may change in the future once I change the API for `TMSDImageCacheProtocol`
        expect([TMSDImageCache.sharedImageCache imageFromMemoryCacheForKey:fullSizeKey]).beNil();
        expect([TMSDImageCache.sharedImageCache imageFromMemoryCacheForKey:thumbnailKey]).beNil();
        
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithCommonTimeout];
}

- (void)test18ThatThumbnailLoadingCanUseFullSizeCache {
    // 2. When using TMSDWebImageManager to load thumbnail image, it will prefers the full size image and thumbnail decoding on the fly, no network
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Thumbnail for loading should prefers full size cache when thumbnail cache miss, like Transformer behavior"];
    
    // 500x500
    CGSize fullSize = CGSizeMake(500, 500);
    TMSDGraphicsImageRenderer *renderer = [[TMSDGraphicsImageRenderer alloc] initWithSize:fullSize];
    UIImage *fullSizeImage = [renderer imageWithActions:^(CGContextRef  _Nonnull context) {
        CGContextSetRGBFillColor(context, 1.0, 0.0, 0.0, 1.0);
        CGContextSetRGBStrokeColor(context, 1.0, 0.0, 0.0, 1.0);
        CGContextFillRect(context, CGRectMake(0, 0, fullSize.width, fullSize.height));
    }];
    expect(fullSizeImage.size).equal(fullSize);
    NSURL *url = [NSURL URLWithString:@"http://via.placeholder.com/500x500.png"];
    NSString *fullSizeKey = [TMSDWebImageManager.sharedManager cacheKeyForURL:url];
    [TMSDImageCache.sharedImageCache storeImageDataToDisk:fullSizeImage.tmsd_imageData forKey:fullSizeKey];
    
    CGSize thumbnailSize = CGSizeMake(100, 100);
    NSString *thumbnailKey = TMSDThumbnailedKeyForKey(fullSizeKey, thumbnailSize, YES);
    [TMSDImageCache.sharedImageCache removeImageFromDiskForKey:thumbnailKey];
    // Load with thumbnail, should use full size cache instead to decode and scale down
    [TMSDWebImageManager.sharedManager loadImageWithURL:url options:0 context:@{TMSDWebImageContextImageThumbnailPixelSize : @(thumbnailSize)} progress:nil completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, TMSDImageCacheType cacheType, BOOL finished, NSURL * _Nullable imageURL) {
        expect(image.size).equal(thumbnailSize);
        expect(cacheType).equal(TMSDImageCacheTypeDisk);
        expect(finished).beTruthy();
        
        // The thumbnail one should stored into memory and disk cache with thumbnail key as well
        expect([TMSDImageCache.sharedImageCache imageFromMemoryCacheForKey:thumbnailKey].size).equal(thumbnailSize);
        expect([TMSDImageCache.sharedImageCache imageFromDiskCacheForKey:thumbnailKey].size).equal(thumbnailSize);
        
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithCommonTimeout];
}

- (void)test19ThatDifferentThumbnailLoadShouldCallbackDifferentSize {
    // 3. Current TMSDWebImageDownloader use the **URL** as primiary key to bind operation, however, different loading pipeline may ask different image size for same URL, this design does not match
    // We use a hack logic to do a re-decode check when the callback image's decode options does not match the loading pipeline provided, it will re-decode the full data with global queue :)
    // Ugly unless we re-define the design of TMSDWebImageDownloader, maybe change that `addHandlersForProgress` with context options args as well. Different context options need different callback image
    
    NSURL *url = [NSURL URLWithString:@"http://via.placeholder.com/501x501.png"];
    NSString *fullSizeKey = [TMSDWebImageManager.sharedManager cacheKeyForURL:url];
    [TMSDImageCache.sharedImageCache removeImageFromDiskForKey:fullSizeKey];
    for (int i = 490; i < 500; i++) {
        // 490x490, ..., 499x499
        CGSize thumbnailSize = CGSizeMake(i, i);
        NSString *thumbnailKey = TMSDThumbnailedKeyForKey(fullSizeKey, thumbnailSize, YES);
        [TMSDImageCache.sharedImageCache removeImageFromDiskForKey:thumbnailKey];
        XCTestExpectation *expectation = [self expectationWithDescription:[NSString stringWithFormat:@"Different thumbnail loading for same URL should callback different image size: (%dx%d)", i, i]];
        [TMSDImageCache.sharedImageCache removeImageFromDiskForKey:url.absoluteString];
        __block TMSDWebImageCombinedOperation *operation;
        operation = [TMSDWebImageManager.sharedManager loadImageWithURL:url options:0 context:@{TMSDWebImageContextImageThumbnailPixelSize : @(thumbnailSize)} progress:nil completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, TMSDImageCacheType cacheType, BOOL finished, NSURL * _Nullable imageURL) {
            expect(image.size).equal(thumbnailSize);
            expect(cacheType).equal(TMSDImageCacheTypeNone);
            expect(finished).beTruthy();
            
            NSURLRequest *request = ((TMSDWebImageDownloadToken *)operation.loaderOperation).request;
            NSLog(@"thumbnail image size: (%dx%d) loaded with the shared request: %p", i, i, request);
            [expectation fulfill];
        }];
    }
    
    [self waitForExpectationsWithTimeout:kAsyncTestTimeout * 5 handler:nil];
}

- (NSString *)testJPEGPath {
    NSBundle *testBundle = [NSBundle bundleForClass:[self class]];
    return [testBundle pathForResource:@"TestImage" ofType:@"jpg"];
}

@end
