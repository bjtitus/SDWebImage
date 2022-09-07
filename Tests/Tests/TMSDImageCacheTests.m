/*
 * This file is part of the TMSDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import <TMSDWebImage/TMSDTestCase.h>
#import <TMSDWebImage/TMSDWebImageTestCoder.h>
#import <TMSDWebImage/TMSDMockFileManager.h>
#import <TMSDWebImage/TMSDWebImageTestCache.h>

static NSString *kTestImageKeyJPEG = @"TestImageKey.jpg";
static NSString *kTestImageKeyPNG = @"TestImageKey.png";

@interface TMSDImageCacheTests : TMSDTestCase <NSFileManagerDelegate>

@end

@implementation TMSDImageCacheTests

- (void)test01SharedImageCache {
    expect([TMSDImageCache sharedImageCache]).toNot.beNil();
}

- (void)test02Singleton{
    expect([TMSDImageCache sharedImageCache]).to.equal([TMSDImageCache sharedImageCache]);
}

- (void)test03ImageCacheCanBeInstantiated {
    TMSDImageCache *imageCache = [[TMSDImageCache alloc] init];
    expect(imageCache).toNot.equal([TMSDImageCache sharedImageCache]);
}

- (void)test04ClearDiskCache{
    XCTestExpectation *expectation = [self expectationWithDescription:@"Clear disk cache"];
    
    [[TMSDImageCache sharedImageCache] storeImage:[self testJPEGImage] forKey:kTestImageKeyJPEG completion:nil];
    [[TMSDImageCache sharedImageCache] clearDiskOnCompletion:^{
        expect([[TMSDImageCache sharedImageCache] imageFromMemoryCacheForKey:kTestImageKeyJPEG]).to.equal([self testJPEGImage]);
        [[TMSDImageCache sharedImageCache] diskImageExistsWithKey:kTestImageKeyJPEG completion:^(BOOL isInCache) {
            if (!isInCache) {
                [[TMSDImageCache sharedImageCache] calculateSizeWithCompletionBlock:^(NSUInteger fileCount, NSUInteger totalSize) {
                    expect(fileCount).to.equal(0);
                    [[TMSDImageCache sharedImageCache] removeImageForKey:kTestImageKeyJPEG withCompletion:^{
                        [expectation fulfill];
                    }];
                }];
            } else {
                XCTFail(@"Image should not be in cache");
            }
        }];
    }];
    [self waitForExpectationsWithCommonTimeout];
}

- (void)test05ClearMemoryCache{
    XCTestExpectation *expectation = [self expectationWithDescription:@"Clear memory cache"];
    
    [[TMSDImageCache sharedImageCache] storeImage:[self testJPEGImage] forKey:kTestImageKeyJPEG completion:^{
        [[TMSDImageCache sharedImageCache] clearMemory];
        expect([[TMSDImageCache sharedImageCache] imageFromMemoryCacheForKey:kTestImageKeyJPEG]).to.beNil;
        [[TMSDImageCache sharedImageCache] diskImageExistsWithKey:kTestImageKeyJPEG completion:^(BOOL isInCache) {
            if (isInCache) {
                [[TMSDImageCache sharedImageCache] removeImageForKey:kTestImageKeyJPEG withCompletion:^{
                    [expectation fulfill];
                }];
            } else {
                XCTFail(@"Image should be in cache");
            }
        }];
    }];
    [self waitForExpectationsWithCommonTimeout];
}

// Testing storeImage:forKey:
- (void)test06InsertionOfImage {
    XCTestExpectation *expectation = [self expectationWithDescription:@"storeImage forKey"];
    
    UIImage *image = [self testJPEGImage];
    [[TMSDImageCache sharedImageCache] storeImage:image forKey:kTestImageKeyJPEG completion:nil];
    expect([[TMSDImageCache sharedImageCache] imageFromMemoryCacheForKey:kTestImageKeyJPEG]).to.equal(image);
    [[TMSDImageCache sharedImageCache] diskImageExistsWithKey:kTestImageKeyJPEG completion:^(BOOL isInCache) {
        if (isInCache) {
            [[TMSDImageCache sharedImageCache] removeImageForKey:kTestImageKeyJPEG withCompletion:^{
                [expectation fulfill];
            }];
        } else {
            XCTFail(@"Image should be in cache");
        }
    }];
    [self waitForExpectationsWithCommonTimeout];
}

// Testing storeImage:forKey:toDisk:YES
- (void)test07InsertionOfImageForcingDiskStorage {
    XCTestExpectation *expectation = [self expectationWithDescription:@"storeImage forKey toDisk=YES"];
    
    UIImage *image = [self testJPEGImage];
    [[TMSDImageCache sharedImageCache] storeImage:image forKey:kTestImageKeyJPEG toDisk:YES completion:nil];
    expect([[TMSDImageCache sharedImageCache] imageFromMemoryCacheForKey:kTestImageKeyJPEG]).to.equal(image);
    [[TMSDImageCache sharedImageCache] diskImageExistsWithKey:kTestImageKeyJPEG completion:^(BOOL isInCache) {
        if (isInCache) {
            [[TMSDImageCache sharedImageCache] removeImageForKey:kTestImageKeyJPEG withCompletion:^{
                [expectation fulfill];
            }];
        } else {
            XCTFail(@"Image should be in cache");
        }
    }];
    [self waitForExpectationsWithCommonTimeout];
}

// Testing storeImage:forKey:toDisk:NO
- (void)test08InsertionOfImageOnlyInMemory {
    XCTestExpectation *expectation = [self expectationWithDescription:@"storeImage forKey toDisk=NO"];
    UIImage *image = [self testJPEGImage];
    [[TMSDImageCache sharedImageCache] storeImage:image forKey:kTestImageKeyJPEG toDisk:NO completion:nil];
    
    expect([[TMSDImageCache sharedImageCache] imageFromMemoryCacheForKey:kTestImageKeyJPEG]).to.equal([self testJPEGImage]);
    [[TMSDImageCache sharedImageCache] diskImageExistsWithKey:kTestImageKeyJPEG completion:^(BOOL isInCache) {
        if (!isInCache) {
            [expectation fulfill];
        } else {
            XCTFail(@"Image should not be in cache");
        }
    }];
    [[TMSDImageCache sharedImageCache] storeImageToMemory:image forKey:kTestImageKeyJPEG];
    [[TMSDImageCache sharedImageCache] clearMemory];
    expect([[TMSDImageCache sharedImageCache] imageFromMemoryCacheForKey:kTestImageKeyJPEG]).to.beNil();
    [self waitForExpectationsWithCommonTimeout];
}

- (void)test09RetrieveImageThroughNSOperation {
    XCTestExpectation *expectation = [self expectationWithDescription:@"queryCacheOperationForKey"];
    UIImage *imageForTesting = [self testJPEGImage];
    [[TMSDImageCache sharedImageCache] storeImage:imageForTesting forKey:kTestImageKeyJPEG completion:nil];
    id<TMSDWebImageOperation> operation = [[TMSDImageCache sharedImageCache] queryCacheOperationForKey:kTestImageKeyJPEG done:^(UIImage *image, NSData *data, TMSDImageCacheType cacheType) {
        expect(image).to.equal(imageForTesting);
        [[TMSDImageCache sharedImageCache] removeImageForKey:kTestImageKeyJPEG withCompletion:^{
            [expectation fulfill];
        }];
    }];
    expect(operation).toNot.beNil;
    [self waitForExpectationsWithCommonTimeout];
}

- (void)test10RemoveImageForKeyWithCompletion {
    XCTestExpectation *expectation = [self expectationWithDescription:@"removeImageForKey"];
    [[TMSDImageCache sharedImageCache] storeImage:[self testJPEGImage] forKey:kTestImageKeyJPEG completion:nil];
    [[TMSDImageCache sharedImageCache] removeImageForKey:kTestImageKeyJPEG withCompletion:^{
        expect([[TMSDImageCache sharedImageCache] imageFromDiskCacheForKey:kTestImageKeyJPEG]).to.beNil;
        expect([[TMSDImageCache sharedImageCache] imageFromMemoryCacheForKey:kTestImageKeyJPEG]).to.beNil;
        [expectation fulfill];
    }];
    [self waitForExpectationsWithCommonTimeout];
}

- (void)test11RemoveImageforKeyNotFromDiskWithCompletion{
    XCTestExpectation *expectation = [self expectationWithDescription:@"removeImageForKey fromDisk:NO"];
    [[TMSDImageCache sharedImageCache] storeImage:[self testJPEGImage] forKey:kTestImageKeyJPEG completion:nil];
    [[TMSDImageCache sharedImageCache] removeImageForKey:kTestImageKeyJPEG fromDisk:NO withCompletion:^{
        expect([[TMSDImageCache sharedImageCache] imageFromDiskCacheForKey:kTestImageKeyJPEG]).toNot.beNil;
        expect([[TMSDImageCache sharedImageCache] imageFromMemoryCacheForKey:kTestImageKeyJPEG]).to.beNil;
        [expectation fulfill];
    }];
    [self waitForExpectationsWithCommonTimeout];
}

- (void)test12RemoveImageforKeyFromDiskWithCompletion{
    XCTestExpectation *expectation = [self expectationWithDescription:@"removeImageForKey fromDisk:YES"];
    [[TMSDImageCache sharedImageCache] storeImage:[self testJPEGImage] forKey:kTestImageKeyJPEG completion:nil];
    [[TMSDImageCache sharedImageCache] removeImageForKey:kTestImageKeyJPEG fromDisk:YES withCompletion:^{
        expect([[TMSDImageCache sharedImageCache] imageFromDiskCacheForKey:kTestImageKeyJPEG]).to.beNil;
        expect([[TMSDImageCache sharedImageCache] imageFromMemoryCacheForKey:kTestImageKeyJPEG]).to.beNil;
        [expectation fulfill];
    }];
    [self waitForExpectationsWithCommonTimeout];
}

- (void)test13DeleteOldFiles {
    XCTestExpectation *expectation = [self expectationWithDescription:@"deleteOldFiles"];
    [TMSDImageCache sharedImageCache].config.maxDiskAge = 1; // 1 second to mark all as out-dated
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [[TMSDImageCache sharedImageCache] deleteOldFilesWithCompletionBlock:^{
            expect(TMSDImageCache.sharedImageCache.totalDiskCount).equal(0);
            [expectation fulfill];
        }];
    });
    [self waitForExpectationsWithCommonTimeout];
}

- (void)test14QueryCacheFirstFrameOnlyHitMemoryCache {
    NSString *key = kTestGIFURL;
    UIImage *animatedImage = [self testGIFImage];
    [[TMSDImageCache sharedImageCache] storeImageToMemory:animatedImage forKey:key];
    [[TMSDImageCache sharedImageCache] queryCacheOperationForKey:key done:^(UIImage * _Nullable image, NSData * _Nullable data, TMSDImageCacheType cacheType) {
        expect(cacheType).equal(TMSDImageCacheTypeMemory);
        expect(image.tmsd_isAnimated).beTruthy();
        expect(image == animatedImage).beTruthy();
    }];
    [[TMSDImageCache sharedImageCache] queryCacheOperationForKey:key options:TMSDImageCacheDecodeFirstFrameOnly done:^(UIImage * _Nullable image, NSData * _Nullable data, TMSDImageCacheType cacheType) {
        expect(cacheType).equal(TMSDImageCacheTypeMemory);
        expect(image.tmsd_isAnimated).beFalsy();
        expect(image == animatedImage).beFalsy();
    }];
    [[TMSDImageCache sharedImageCache] removeImageFromMemoryForKey:kTestGIFURL];
}

- (void)test15CancelQueryShouldCallbackOnceInSync {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Cancel Query Should Callback Once In Sync"];
    expectation.expectedFulfillmentCount = 1;
    NSString *key = @"test15CancelQueryShouldCallbackOnceInSync";
    [TMSDImageCache.sharedImageCache removeImageFromMemoryForKey:key];
    [TMSDImageCache.sharedImageCache removeImageFromDiskForKey:key];
    __block BOOL callced = NO;
    TMSDImageCacheToken *token = [TMSDImageCache.sharedImageCache queryCacheOperationForKey:key done:^(UIImage * _Nullable image, NSData * _Nullable data, TMSDImageCacheType cacheType) {
        callced = true;
        [expectation fulfill]; // callback once fulfill once
    }];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        expect(callced).beFalsy();
        [token cancel]; // sync
        expect(callced).beTruthy();
    });
    
    [self waitForExpectationsWithCommonTimeout];
}

- (void)test20InitialCacheSize{
    expect([[TMSDImageCache sharedImageCache] totalDiskSize]).to.equal(0);
}

- (void)test21InitialDiskCount{
    XCTestExpectation *expectation = [self expectationWithDescription:@"getDiskCount"];
    [[TMSDImageCache sharedImageCache] storeImage:[self testJPEGImage] forKey:kTestImageKeyJPEG completion:^{
        expect([[TMSDImageCache sharedImageCache] totalDiskCount]).to.equal(1);
        [[TMSDImageCache sharedImageCache] removeImageForKey:kTestImageKeyJPEG withCompletion:^{
            [expectation fulfill];
        }];
    }];
    [self waitForExpectationsWithCommonTimeout];
}

- (void)test31CachePathForAnyKey{
    NSString *path = [[TMSDImageCache sharedImageCache] cachePathForKey:kTestImageKeyJPEG];
    expect(path).toNot.beNil;
}

- (void)test32CachePathForNilKey{
    NSString *path = [[TMSDImageCache sharedImageCache] cachePathForKey:nil];
    expect(path).to.beNil;
}

- (void)test33CachePathForExistingKey{
    XCTestExpectation *expectation = [self expectationWithDescription:@"cachePathForKey inPath"];
    [[TMSDImageCache sharedImageCache] storeImage:[self testJPEGImage] forKey:kTestImageKeyJPEG completion:^{
        NSString *path = [[TMSDImageCache sharedImageCache] cachePathForKey:kTestImageKeyJPEG];
        expect(path).notTo.beNil;
        [[TMSDImageCache sharedImageCache] removeImageForKey:kTestImageKeyJPEG withCompletion:^{
            [expectation fulfill];
        }];
    }];
    [self waitForExpectationsWithCommonTimeout];
}

- (void)test34CachePathForSimpleKeyWithExtension {
    NSString *cachePath = [[TMSDImageCache sharedImageCache] cachePathForKey:kTestJPEGURL];
    expect(cachePath).toNot.beNil();
    expect([cachePath pathExtension]).to.equal(@"jpg");
}

- (void)test35CachePathForKeyWithDotButNoExtension {
    NSString *urlString = @"https://maps.googleapis.com/maps/api/staticmap?center=48.8566,2.3522&format=png&maptype=roadmap&scale=2&size=375x200&zoom=15";
    NSString *cachePath = [[TMSDImageCache sharedImageCache] cachePathForKey:urlString];
    expect(cachePath).toNot.beNil();
    expect([cachePath pathExtension]).to.equal(@"");
}

- (void)test36CachePathForKeyWithURLQueryParams {
    NSString *urlString = @"https://imggen.alicdn.com/3b11cea896a9438329d85abfb07b30a8.jpg?aid=tanx&tid=1166&m=%7B%22img_url%22%3A%22https%3A%2F%2Fgma.alicdn.com%2Fbao%2Fuploaded%2Fi4%2F1695306010722305097%2FTB2S2KjkHtlpuFjSspoXXbcDpXa_%21%210-saturn_solar.jpg_sum.jpg%22%2C%22title%22%3A%22%E6%A4%8D%E7%89%A9%E8%94%B7%E8%96%87%E7%8E%AB%E7%91%B0%E8%8A%B1%22%2C%22promot_name%22%3A%22%22%2C%22itemid%22%3A%22546038044448%22%7D&e=cb88dab197bfaa19804f6ec796ca906dab536b88fe6d4475795c7ee661a7ede1&size=640x246";
    NSString *cachePath = [[TMSDImageCache sharedImageCache] cachePathForKey:urlString];
    expect(cachePath).toNot.beNil();
    expect([cachePath pathExtension]).to.equal(@"jpg");
}

- (void)test37CachePathForKeyWithTooLongExtension {
    NSString *urlString = @"https://imggen.alicdn.com/3b11cea896a9438329d85abfb07b30a8.jpgasaaaaaaaaaaaaaaaaaaaajjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjaaaaaaaaaaaaaaaaajjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjj";
    NSString *cachePath = [[TMSDImageCache sharedImageCache] cachePathForKey:urlString];
    expect(cachePath).toNot.beNil();
    expect([cachePath pathExtension]).to.equal(@"");
}

- (void)test40InsertionOfImageData {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Insertion of image data works"];
    
    UIImage *image = [[UIImage alloc] initWithContentsOfFile:[self testJPEGPath]];
    NSData *imageData = [image tmsd_imageDataAsFormat:TMSDImageFormatJPEG];
    [[TMSDImageCache sharedImageCache] storeImageDataToDisk:imageData forKey:kTestImageKeyJPEG];
    
    expect([[TMSDImageCache sharedImageCache] diskImageDataExistsWithKey:kTestImageKeyJPEG]).beTruthy();
    UIImage *storedImageFromMemory = [[TMSDImageCache sharedImageCache] imageFromMemoryCacheForKey:kTestImageKeyJPEG];
    expect(storedImageFromMemory).to.equal(nil);
    
    NSString *cachePath = [[TMSDImageCache sharedImageCache] cachePathForKey:kTestImageKeyJPEG];
    UIImage *cachedImage = [[UIImage alloc] initWithContentsOfFile:cachePath];
    NSData *storedImageData = [cachedImage tmsd_imageDataAsFormat:TMSDImageFormatJPEG];
    expect(storedImageData.length).to.beGreaterThan(0);
    expect(cachedImage.size).to.equal(image.size);
    // can't directly compare image and cachedImage because apparently there are some slight differences, even though the image is the same
    
    [[TMSDImageCache sharedImageCache] diskImageExistsWithKey:kTestImageKeyJPEG completion:^(BOOL isInCache) {
        expect(isInCache).to.equal(YES);
        
        [[TMSDImageCache sharedImageCache] removeImageForKey:kTestImageKeyJPEG withCompletion:^{
            [expectation fulfill];
        }];
    }];
    
    [self waitForExpectationsWithCommonTimeout];
}

- (void)test41ThatCustomDecoderWorksForImageCache {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Custom decoder for TMSDImageCache not works"];
    TMSDImageCache *cache = [[TMSDImageCache alloc] initWithNamespace:@"TestDecode"];
    TMSDWebImageTestCoder *testDecoder = [[TMSDWebImageTestCoder alloc] init];
    [[TMSDImageCodersManager sharedManager] addCoder:testDecoder];
    NSString * testImagePath = [[NSBundle bundleForClass:[self class]] pathForResource:@"TestImage" ofType:@"png"];
    UIImage *image = [[UIImage alloc] initWithContentsOfFile:testImagePath];
    NSString *key = @"TestPNGImageEncodedToDataAndRetrieveToJPEG";
    
    [cache storeImage:image imageData:nil forKey:key toDisk:YES completion:^{
        [cache clearMemory];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
        SEL diskImageDataBySearchingAllPathsForKey = @selector(diskImageDataBySearchingAllPathsForKey:);
#pragma clang diagnostic pop
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        NSData *data = [cache performSelector:diskImageDataBySearchingAllPathsForKey withObject:key];
#pragma clang diagnostic pop
        NSString *str1 = @"TestEncode";
        NSString *str2 = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        if (![str1 isEqualToString:str2]) {
            XCTFail(@"Custom decoder not work for TMSDImageCache, check -[TMSDWebImageTestDecoder encodedDataWithImage:format:]");
        }
        
        UIImage *diskCacheImage = [cache imageFromDiskCacheForKey:key];
        
        // Decoded result is JPEG
        NSString * decodedImagePath = [[NSBundle bundleForClass:[self class]] pathForResource:@"TestImage" ofType:@"jpg"];
        UIImage *testJPEGImage = [[UIImage alloc] initWithContentsOfFile:decodedImagePath];
        
        NSData *data1 = [testJPEGImage tmsd_imageDataAsFormat:TMSDImageFormatPNG];
        NSData *data2 = [diskCacheImage tmsd_imageDataAsFormat:TMSDImageFormatPNG];
        
        if (![data1 isEqualToData:data2]) {
            XCTFail(@"Custom decoder not work for TMSDImageCache, check -[TMSDWebImageTestDecoder decodedImageWithData:]");
        }
        
        [[TMSDImageCodersManager sharedManager] removeCoder:testDecoder];
        
        [[TMSDImageCache sharedImageCache] removeImageForKey:key withCompletion:^{
            [expectation fulfill];
        }];
    }];
    
    [self waitForExpectationsWithCommonTimeout];
}

- (void)test41StoreImageDataToDiskWithCustomFileManager {
    NSData *imageData = [NSData dataWithContentsOfFile:[self testJPEGPath]];
    NSError *targetError = [NSError errorWithDomain:NSCocoaErrorDomain code:NSFileWriteNoPermissionError userInfo:nil];
    
    TMSDMockFileManager *fileManager = [[TMSDMockFileManager alloc] init];
    fileManager.mockSelectors = @{NSStringFromSelector(@selector(createDirectoryAtPath:withIntermediateDirectories:attributes:error:)) : targetError};
    expect(fileManager.lastError).to.beNil();
    
    TMSDImageCacheConfig *config = [TMSDImageCacheConfig new];
    config.fileManager = fileManager;
    // This disk cache path creation will be mocked with error.
    TMSDImageCache *cache = [[TMSDImageCache alloc] initWithNamespace:@"test" diskCacheDirectory:@"/" config:config];
    [cache storeImageDataToDisk:imageData
                         forKey:kTestImageKeyJPEG];
    expect(fileManager.lastError).equal(targetError);
}

- (void)test41MatchAnimatedImageClassWorks {
    XCTestExpectation *expectation = [self expectationWithDescription:@"MatchAnimatedImageClass option should work"];
    UIImage *image = [[UIImage alloc] initWithContentsOfFile:self.testGIFPath];
    
    NSString *kAnimatedImageKey = @"kAnimatedImageKey";
    
    // Store UIImage into cache
    [[TMSDImageCache sharedImageCache] storeImageToMemory:image forKey:kAnimatedImageKey];
    
    // `MatchAnimatedImageClass` will cause query failed because class does not match
    [TMSDImageCache.sharedImageCache queryCacheOperationForKey:kAnimatedImageKey options:TMSDImageCacheMatchAnimatedImageClass context:@{TMSDWebImageContextAnimatedImageClass : TMSDAnimatedImage.class} done:^(UIImage * _Nullable image1, NSData * _Nullable data1, TMSDImageCacheType cacheType1) {
        expect(image1).beNil();
        // This should query success with UIImage
        [TMSDImageCache.sharedImageCache queryCacheOperationForKey:kAnimatedImageKey options:0 context:@{TMSDWebImageContextAnimatedImageClass : TMSDAnimatedImage.class} done:^(UIImage * _Nullable image2, NSData * _Nullable data2, TMSDImageCacheType cacheType2) {
            expect(image2).notTo.beNil();
            expect(image2).equal(image);
            
            [expectation fulfill];
        }];
    }];
    
    // Test sync version API `imageFromCacheForKey` as well
    expect([TMSDImageCache.sharedImageCache imageFromCacheForKey:kAnimatedImageKey options:TMSDImageCacheMatchAnimatedImageClass context:@{TMSDWebImageContextAnimatedImageClass : TMSDAnimatedImage.class}]).beNil();
    expect([TMSDImageCache.sharedImageCache imageFromCacheForKey:kAnimatedImageKey options:0 context:@{TMSDWebImageContextAnimatedImageClass : TMSDAnimatedImage.class}]).notTo.beNil();
    
    [self waitForExpectationsWithCommonTimeout];
}

- (void)test42StoreCacheWithImageAndFormatWithoutImageData {
    XCTestExpectation *expectation1 = [self expectationWithDescription:@"StoreImage UIImage without tmsd_imageFormat should use PNG for alpha channel"];
    XCTestExpectation *expectation2 = [self expectationWithDescription:@"StoreImage UIImage without tmsd_imageFormat should use JPEG for non-alpha channel"];
    XCTestExpectation *expectation3 = [self expectationWithDescription:@"StoreImage UIImage/UIAnimatedImage with tmsd_imageFormat should use that format"];
    XCTestExpectation *expectation4 = [self expectationWithDescription:@"StoreImage TMSDAnimatedImage should use animatedImageData"];
    XCTestExpectation *expectation5 = [self expectationWithDescription:@"StoreImage UIAnimatedImage without tmsd_imageFormat should use GIF"];
    
    NSString *kAnimatedImageKey1 = @"kAnimatedImageKey1";
    NSString *kAnimatedImageKey2 = @"kAnimatedImageKey2";
    NSString *kAnimatedImageKey3 = @"kAnimatedImageKey3";
    NSString *kAnimatedImageKey4 = @"kAnimatedImageKey4";
    NSString *kAnimatedImageKey5 = @"kAnimatedImageKey5";
    
    // Case 1: UIImage without `tmsd_imageFormat` should use PNG for alpha channel
    NSData *pngData = [NSData dataWithContentsOfFile:[self testPNGPath]];
    UIImage *pngImage = [UIImage tmsd_imageWithData:pngData];
    expect(pngImage.tmsd_isAnimated).beFalsy();
    expect(pngImage.tmsd_imageFormat).equal(TMSDImageFormatPNG);
    // Remove tmsd_imageFormat
    pngImage.tmsd_imageFormat = TMSDImageFormatUndefined;
    // Check alpha channel
    expect([TMSDImageCoderHelper CGImageContainsAlpha:pngImage.CGImage]).beTruthy();
    
    [TMSDImageCache.sharedImageCache storeImage:pngImage forKey:kAnimatedImageKey1 toDisk:YES completion:^{
        UIImage *diskImage = [TMSDImageCache.sharedImageCache imageFromDiskCacheForKey:kAnimatedImageKey1];
        // Should save to PNG
        expect(diskImage.tmsd_isAnimated).beFalsy();
        expect(diskImage.tmsd_imageFormat).equal(TMSDImageFormatPNG);
        [expectation1 fulfill];
    }];
    
    // Case 2: UIImage without `tmsd_imageFormat` should use JPEG for non-alpha channel
    TMSDGraphicsImageRendererFormat *format = [TMSDGraphicsImageRendererFormat preferredFormat];
    format.opaque = YES;
    TMSDGraphicsImageRenderer *renderer = [[TMSDGraphicsImageRenderer alloc] initWithSize:pngImage.size format:format];
    // Non-alpha image, also test `TMSDGraphicsImageRenderer` behavior here :)
    UIImage *nonAlphaImage = [renderer imageWithActions:^(CGContextRef  _Nonnull context) {
        [pngImage drawInRect:CGRectMake(0, 0, pngImage.size.width, pngImage.size.height)];
    }];
    expect(nonAlphaImage).notTo.beNil();
    expect([TMSDImageCoderHelper CGImageContainsAlpha:nonAlphaImage.CGImage]).beFalsy();
    
    [TMSDImageCache.sharedImageCache storeImage:nonAlphaImage forKey:kAnimatedImageKey2 toDisk:YES completion:^{
        UIImage *diskImage = [TMSDImageCache.sharedImageCache imageFromDiskCacheForKey:kAnimatedImageKey2];
        // Should save to JPEG
        expect(diskImage.tmsd_isAnimated).beFalsy();
        expect(diskImage.tmsd_imageFormat).equal(TMSDImageFormatJPEG);
        [expectation2 fulfill];
    }];
    
    NSData *gifData = [NSData dataWithContentsOfFile:[self testGIFPath]];
    UIImage *gifImage = [UIImage tmsd_imageWithData:gifData]; // UIAnimatedImage
    expect(gifImage.tmsd_isAnimated).beTruthy();
    expect(gifImage.tmsd_imageFormat).equal(TMSDImageFormatGIF);
    
    // Case 3: UIImage with `tmsd_imageFormat` should use that format
    [TMSDImageCache.sharedImageCache storeImage:gifImage forKey:kAnimatedImageKey3 toDisk:YES completion:^{
        UIImage *diskImage = [TMSDImageCache.sharedImageCache imageFromDiskCacheForKey:kAnimatedImageKey3];
        // Should save to GIF
        expect(diskImage.tmsd_isAnimated).beTruthy();
        expect(diskImage.tmsd_imageFormat).equal(TMSDImageFormatGIF);
        [expectation3 fulfill];
    }];
    
    // Case 4: TMSDAnimatedImage should use `animatedImageData`
    TMSDAnimatedImage *animatedImage = [TMSDAnimatedImage imageWithData:gifData];
    expect(animatedImage.animatedImageData).notTo.beNil();
    [TMSDImageCache.sharedImageCache storeImage:animatedImage forKey:kAnimatedImageKey4 toDisk:YES completion:^{
        NSData *data = [TMSDImageCache.sharedImageCache diskImageDataForKey:kAnimatedImageKey4];
        // Should save with animatedImageData
        expect(data).equal(animatedImage.animatedImageData);
        [expectation4 fulfill];
    }];
    
    // Case 5: UIAnimatedImage without tmsd_imageFormat should use GIF not APNG
    NSData *apngData = [NSData dataWithContentsOfFile:[self testAPNGPath]];
    UIImage *apngImage = [UIImage tmsd_imageWithData:apngData];
    expect(apngImage.tmsd_isAnimated).beTruthy();
    expect(apngImage.tmsd_imageFormat).equal(TMSDImageFormatPNG);
    // Remove tmsd_imageFormat
    apngImage.tmsd_imageFormat = TMSDImageFormatUndefined;
    
    [TMSDImageCache.sharedImageCache storeImage:apngImage forKey:kAnimatedImageKey5 toDisk:YES completion:^{
        UIImage *diskImage = [TMSDImageCache.sharedImageCache imageFromDiskCacheForKey:kAnimatedImageKey5];
        // Should save to GIF
        expect(diskImage.tmsd_isAnimated).beTruthy();
        expect(diskImage.tmsd_imageFormat).equal(TMSDImageFormatGIF);
        [expectation5 fulfill];
    }];
    
    [self waitForExpectationsWithCommonTimeout];
}

- (void)test43CustomDefaultCacheDirectory {
    NSArray<NSString *> *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *testDirectory = [paths.firstObject stringByAppendingPathComponent:@"CustomDefaultCacheDirectory"];
    NSString *defaultDirectory = [paths.firstObject stringByAppendingPathComponent:@"com.hackemist.TMSDImageCache"];
    NSString *namespace = @"Test";
    
    // Default cache path
    expect(TMSDImageCache.defaultDiskCacheDirectory).equal(defaultDirectory);
    TMSDImageCache *cache1 = [[TMSDImageCache alloc] initWithNamespace:namespace];
    expect(cache1.diskCachePath).equal([defaultDirectory stringByAppendingPathComponent:namespace]);
    // Custom cache path
    TMSDImageCache.defaultDiskCacheDirectory = testDirectory;
    TMSDImageCache *cache2 = [[TMSDImageCache alloc] initWithNamespace:namespace];
    expect(cache2.diskCachePath).equal([testDirectory stringByAppendingPathComponent:namespace]);
    // Check reset
    TMSDImageCache.defaultDiskCacheDirectory = nil;
    expect(TMSDImageCache.defaultDiskCacheDirectory).equal(defaultDirectory);
}

#pragma mark - TMSDMemoryCache & TMSDDiskCache
- (void)test42CustomMemoryCache {
    TMSDImageCacheConfig *config = [[TMSDImageCacheConfig alloc] init];
    config.memoryCacheClass = [TMSDWebImageTestMemoryCache class];
    NSString *nameSpace = @"TMSDWebImageTestMemoryCache";
    TMSDImageCache *cache = [[TMSDImageCache alloc] initWithNamespace:nameSpace diskCacheDirectory:nil config:config];
    TMSDWebImageTestMemoryCache *memCache = cache.memoryCache;
    expect([memCache isKindOfClass:[TMSDWebImageTestMemoryCache class]]).to.beTruthy();
}

- (void)test43CustomDiskCache {
    TMSDImageCacheConfig *config = [[TMSDImageCacheConfig alloc] init];
    config.diskCacheClass = [TMSDWebImageTestDiskCache class];
    NSString *nameSpace = @"TMSDWebImageTestDiskCache";
    TMSDImageCache *cache = [[TMSDImageCache alloc] initWithNamespace:nameSpace diskCacheDirectory:nil config:config];
    TMSDWebImageTestDiskCache *diskCache = cache.diskCache;
    expect([diskCache isKindOfClass:[TMSDWebImageTestDiskCache class]]).to.beTruthy();
}

- (void)test44DiskCacheMigrationFromOldVersion {
    TMSDImageCacheConfig *config = [[TMSDImageCacheConfig alloc] init];
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    config.fileManager = fileManager;
    
    // Fake to store a.png into old path
    NSString *newDefaultPath = [[[self userCacheDirectory] stringByAppendingPathComponent:@"com.hackemist.TMSDImageCache"] stringByAppendingPathComponent:@"default"];
    NSString *oldDefaultPath = [[[self userCacheDirectory] stringByAppendingPathComponent:@"default"] stringByAppendingPathComponent:@"com.hackemist.TMSDWebImageCache.default"];
    [fileManager createDirectoryAtPath:oldDefaultPath withIntermediateDirectories:YES attributes:nil error:nil];
    [fileManager createFileAtPath:[oldDefaultPath stringByAppendingPathComponent:@"a.png"] contents:[NSData dataWithContentsOfFile:[self testPNGPath]] attributes:nil];
    // Call migration
    TMSDDiskCache *diskCache = [[TMSDDiskCache alloc] initWithCachePath:newDefaultPath config:config];
    [diskCache moveCacheDirectoryFromPath:oldDefaultPath toPath:newDefaultPath];
    
    // Expect a.png into new path
    BOOL exist = [fileManager fileExistsAtPath:[newDefaultPath stringByAppendingPathComponent:@"a.png"]];
    expect(exist).beTruthy();
}

- (void)test45DiskCacheRemoveExpiredData {
    NSString *cachePath = [[self userCacheDirectory] stringByAppendingPathComponent:@"disk"];
    TMSDImageCacheConfig *config = TMSDImageCacheConfig.defaultCacheConfig;
    config.maxDiskAge = 1; // 1 second
    config.maxDiskSize = 10; // 10 KB
    TMSDDiskCache *diskCache = [[TMSDDiskCache alloc] initWithCachePath:cachePath config:config];
    [diskCache removeAllData];
    expect(diskCache.totalSize).equal(0);
    expect(diskCache.totalCount).equal(0);
    // 20KB -> maxDiskSize
    NSUInteger length = 20;
    void *bytes = malloc(length);
    NSData *data = [NSData dataWithBytes:bytes length:length];
    free(bytes);
    [diskCache setData:data forKey:@"20KB"];
    expect(diskCache.totalSize).equal(length);
    expect(diskCache.totalCount).equal(1);
    [diskCache removeExpiredData];
    expect(diskCache.totalSize).equal(0);
    expect(diskCache.totalCount).equal(0);
    // 1KB with 5s -> maxDiskAge
    XCTestExpectation *expectation = [self expectationWithDescription:@"TMSDDiskCache removeExpireData timeout"];
    length = 1;
    bytes = malloc(length);
    data = [NSData dataWithBytes:bytes length:length];
    free(bytes);
    [diskCache setData:data forKey:@"1KB"];
    expect(diskCache.totalSize).equal(length);
    expect(diskCache.totalCount).equal(1);
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [diskCache removeExpiredData];
        expect(diskCache.totalSize).equal(0);
        expect(diskCache.totalCount).equal(0);
        [expectation fulfill];
    });
    [self waitForExpectationsWithTimeout:5 handler:nil];
}

#if TMSD_UIKIT
- (void)test46MemoryCacheWeakCache {
    TMSDMemoryCache *memoryCache = [[TMSDMemoryCache alloc] init];
    memoryCache.config.shouldUseWeakMemoryCache = NO;
    memoryCache.config.maxMemoryCost = 10;
    memoryCache.config.maxMemoryCount = 5;
    expect(memoryCache.countLimit).equal(5);
    expect(memoryCache.totalCostLimit).equal(10);
    // Don't use weak cache
    NSObject *object = [NSObject new];
    [memoryCache setObject:object forKey:@"1"];
    [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationDidReceiveMemoryWarningNotification object:nil];
    NSObject *cachedObject = [memoryCache objectForKey:@"1"];
    expect(cachedObject).beNil();
    // Use weak cache
    memoryCache.config.shouldUseWeakMemoryCache = YES;
    object = [NSObject new];
    [memoryCache setObject:object forKey:@"1"];
    [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationDidReceiveMemoryWarningNotification object:nil];
    cachedObject = [memoryCache objectForKey:@"1"];
    expect(object).equal(cachedObject);
}
#endif

- (void)test47DiskCacheExtendedData {
    XCTestExpectation *expectation = [self expectationWithDescription:@"TMSDImageCache extended data read/write works"];
    UIImage *image = [self testPNGImage];
    NSDictionary *extendedObject = @{@"Test" : @"Object"};
    image.tmsd_extendedObject = extendedObject;
    [TMSDImageCache.sharedImageCache removeImageFromMemoryForKey:kTestImageKeyPNG];
    [TMSDImageCache.sharedImageCache removeImageFromDiskForKey:kTestImageKeyPNG];
    // Write extended data
    [TMSDImageCache.sharedImageCache storeImage:image forKey:kTestImageKeyPNG completion:^{
        NSData *extendedData = [TMSDImageCache.sharedImageCache.diskCache extendedDataForKey:kTestImageKeyPNG];
        expect(extendedData).toNot.beNil();
        // Read extended data
        UIImage *newImage = [TMSDImageCache.sharedImageCache imageFromDiskCacheForKey:kTestImageKeyPNG];
        id newExtendedObject = newImage.tmsd_extendedObject;
        expect(extendedObject).equal(newExtendedObject);
        // Remove extended data
        [TMSDImageCache.sharedImageCache.diskCache setExtendedData:nil forKey:kTestImageKeyPNG];
        [expectation fulfill];
    }];
    [self waitForExpectationsWithCommonTimeout];
}

#pragma mark - TMSDImageCache & TMSDImageCachesManager
- (void)test49TMSDImageCacheQueryOp {
    XCTestExpectation *expectation = [self expectationWithDescription:@"TMSDImageCache query op works"];
    NSData *imageData = [[TMSDImageCodersManager sharedManager] encodedDataWithImage:[self testJPEGImage] format:TMSDImageFormatJPEG options:nil];
    [[TMSDImageCache sharedImageCache] storeImageDataToDisk:imageData forKey:kTestImageKeyJPEG];
    
    [[TMSDImageCachesManager sharedManager] queryImageForKey:kTestImageKeyJPEG options:0 context:@{TMSDWebImageContextStoreCacheType : @(TMSDImageCacheTypeDisk)} cacheType:TMSDImageCacheTypeAll completion:^(UIImage * _Nullable image, NSData * _Nullable data, TMSDImageCacheType cacheType) {
        expect(image).notTo.beNil();
        expect([[TMSDImageCache sharedImageCache] imageFromMemoryCacheForKey:kTestImageKeyJPEG]).beNil();
        [expectation fulfill];
    }];
    [self waitForExpectationsWithCommonTimeout];
}

- (void)test50TMSDImageCacheQueryOp {
    XCTestExpectation *expectation = [self expectationWithDescription:@"TMSDImageCache query op works"];
    [[TMSDImageCache sharedImageCache] storeImage:[self testJPEGImage] forKey:kTestImageKeyJPEG toDisk:NO completion:nil];
    [[TMSDImageCachesManager sharedManager] queryImageForKey:kTestImageKeyJPEG options:0 context:nil cacheType:TMSDImageCacheTypeAll completion:^(UIImage * _Nullable image, NSData * _Nullable data, TMSDImageCacheType cacheType) {
        expect(image).notTo.beNil();
        [expectation fulfill];
    }];
    [self waitForExpectationsWithCommonTimeout];
}

- (void)test51TMSDImageCacheStoreOp {
    XCTestExpectation *expectation = [self expectationWithDescription:@"TMSDImageCache store op works"];
    [[TMSDImageCachesManager sharedManager] storeImage:[self testJPEGImage] imageData:nil forKey:kTestImageKeyJPEG cacheType:TMSDImageCacheTypeAll completion:^{
        UIImage *image = [[TMSDImageCache sharedImageCache] imageFromMemoryCacheForKey:kTestImageKeyJPEG];
        expect(image).notTo.beNil();
        [[TMSDImageCache sharedImageCache] diskImageExistsWithKey:kTestImageKeyJPEG completion:^(BOOL isInCache) {
            expect(isInCache).to.beTruthy();
            [expectation fulfill];
        }];
    }];
    [self waitForExpectationsWithCommonTimeout];
}

- (void)test52TMSDImageCacheRemoveOp {
    XCTestExpectation *expectation = [self expectationWithDescription:@"TMSDImageCache remove op works"];
    [[TMSDImageCachesManager sharedManager] removeImageForKey:kTestImageKeyJPEG cacheType:TMSDImageCacheTypeDisk completion:^{
        UIImage *memoryImage = [[TMSDImageCache sharedImageCache] imageFromMemoryCacheForKey:kTestImageKeyJPEG];
        expect(memoryImage).notTo.beNil();
        [[TMSDImageCache sharedImageCache] diskImageExistsWithKey:kTestImageKeyJPEG completion:^(BOOL isInCache) {
            expect(isInCache).to.beFalsy();
            [expectation fulfill];
        }];
    }];
    [self waitForExpectationsWithCommonTimeout];
}

- (void)test53TMSDImageCacheContainsOp {
    XCTestExpectation *expectation = [self expectationWithDescription:@"TMSDImageCache contains op works"];
    [[TMSDImageCachesManager sharedManager] containsImageForKey:kTestImageKeyJPEG cacheType:TMSDImageCacheTypeAll completion:^(TMSDImageCacheType containsCacheType) {
        expect(containsCacheType).equal(TMSDImageCacheTypeMemory);
        [expectation fulfill];
    }];
    [self waitForExpectationsWithCommonTimeout];
}

- (void)test54TMSDImageCacheClearOp {
    XCTestExpectation *expectation = [self expectationWithDescription:@"TMSDImageCache clear op works"];
    [[TMSDImageCachesManager sharedManager] clearWithCacheType:TMSDImageCacheTypeAll completion:^{
        UIImage *memoryImage = [[TMSDImageCache sharedImageCache] imageFromMemoryCacheForKey:kTestImageKeyJPEG];
        expect(memoryImage).to.beNil();
        [[TMSDImageCache sharedImageCache] diskImageExistsWithKey:kTestImageKeyJPEG completion:^(BOOL isInCache) {
            expect(isInCache).to.beFalsy();
            [expectation fulfill];
        }];
    }];
    [self waitForExpectationsWithCommonTimeout];
}

- (void)test55TMSDImageCachesManagerOperationPolicySimple {
    TMSDImageCachesManager *cachesManager = [[TMSDImageCachesManager alloc] init];
    TMSDImageCache *cache1 = [[TMSDImageCache alloc] initWithNamespace:@"cache1"];
    TMSDImageCache *cache2 = [[TMSDImageCache alloc] initWithNamespace:@"cache2"];
    cachesManager.caches = @[cache1, cache2];
    
    [[NSFileManager defaultManager] removeItemAtPath:cache1.diskCachePath error:nil];
    [[NSFileManager defaultManager] removeItemAtPath:cache2.diskCachePath error:nil];
    
    // LowestOnly
    cachesManager.queryOperationPolicy = TMSDImageCachesManagerOperationPolicyLowestOnly;
    cachesManager.storeOperationPolicy = TMSDImageCachesManagerOperationPolicyLowestOnly;
    cachesManager.removeOperationPolicy = TMSDImageCachesManagerOperationPolicyLowestOnly;
    cachesManager.containsOperationPolicy = TMSDImageCachesManagerOperationPolicyLowestOnly;
    cachesManager.clearOperationPolicy = TMSDImageCachesManagerOperationPolicyLowestOnly;
    [cachesManager queryImageForKey:kTestImageKeyJPEG options:0 context:nil cacheType:TMSDImageCacheTypeAll completion:^(UIImage * _Nullable image, NSData * _Nullable data, TMSDImageCacheType cacheType) {
        expect(image).to.beNil();
    }];
    [cachesManager storeImage:[self testJPEGImage] imageData:nil forKey:kTestImageKeyJPEG cacheType:TMSDImageCacheTypeMemory completion:nil];
    // Check Logic works, cache1 only
    UIImage *memoryImage1 = [cache1 imageFromMemoryCacheForKey:kTestImageKeyJPEG];
    expect(memoryImage1).equal([self testJPEGImage]);
    [cachesManager containsImageForKey:kTestImageKeyJPEG cacheType:TMSDImageCacheTypeMemory completion:^(TMSDImageCacheType containsCacheType) {
        expect(containsCacheType).equal(TMSDImageCacheTypeMemory);
    }];
    [cachesManager removeImageForKey:kTestImageKeyJPEG cacheType:TMSDImageCacheTypeMemory completion:nil];
    [cachesManager clearWithCacheType:TMSDImageCacheTypeMemory completion:nil];
    
    // HighestOnly
    cachesManager.queryOperationPolicy = TMSDImageCachesManagerOperationPolicyHighestOnly;
    cachesManager.storeOperationPolicy = TMSDImageCachesManagerOperationPolicyHighestOnly;
    cachesManager.removeOperationPolicy = TMSDImageCachesManagerOperationPolicyHighestOnly;
    cachesManager.containsOperationPolicy = TMSDImageCachesManagerOperationPolicyHighestOnly;
    cachesManager.clearOperationPolicy = TMSDImageCachesManagerOperationPolicyHighestOnly;
    [cachesManager queryImageForKey:kTestImageKeyPNG options:0 context:nil cacheType:TMSDImageCacheTypeAll completion:^(UIImage * _Nullable image, NSData * _Nullable data, TMSDImageCacheType cacheType) {
        expect(image).to.beNil();
    }];
    [cachesManager storeImage:[self testPNGImage] imageData:nil forKey:kTestImageKeyPNG cacheType:TMSDImageCacheTypeMemory completion:nil];
    // Check Logic works, cache2 only
    UIImage *memoryImage2 = [cache2 imageFromMemoryCacheForKey:kTestImageKeyPNG];
    expect(memoryImage2).equal([self testPNGImage]);
    [cachesManager containsImageForKey:kTestImageKeyPNG cacheType:TMSDImageCacheTypeMemory completion:^(TMSDImageCacheType containsCacheType) {
        expect(containsCacheType).equal(TMSDImageCacheTypeMemory);
    }];
    [cachesManager removeImageForKey:kTestImageKeyPNG cacheType:TMSDImageCacheTypeMemory completion:nil];
    [cachesManager clearWithCacheType:TMSDImageCacheTypeMemory completion:nil];
}

- (void)test56TMSDImageCachesManagerOperationPolicyConcurrent {
    XCTestExpectation *expectation = [self expectationWithDescription:@"TMSDImageCachesManager operation cocurrent policy works"];
    TMSDImageCachesManager *cachesManager = [[TMSDImageCachesManager alloc] init];
    TMSDImageCache *cache1 = [[TMSDImageCache alloc] initWithNamespace:@"cache1"];
    TMSDImageCache *cache2 = [[TMSDImageCache alloc] initWithNamespace:@"cache2"];
    cachesManager.caches = @[cache1, cache2];
    
    [[NSFileManager defaultManager] removeItemAtPath:cache1.diskCachePath error:nil];
    [[NSFileManager defaultManager] removeItemAtPath:cache2.diskCachePath error:nil];
    
    NSString *kConcurrentTestImageKey = @"kConcurrentTestImageKey";
    
    // Cocurrent
    // Check all concurrent op
    cachesManager.queryOperationPolicy = TMSDImageCachesManagerOperationPolicyConcurrent;
    cachesManager.storeOperationPolicy = TMSDImageCachesManagerOperationPolicyConcurrent;
    cachesManager.removeOperationPolicy = TMSDImageCachesManagerOperationPolicyConcurrent;
    cachesManager.containsOperationPolicy = TMSDImageCachesManagerOperationPolicyConcurrent;
    cachesManager.clearOperationPolicy = TMSDImageCachesManagerOperationPolicyConcurrent;
    [cachesManager queryImageForKey:kConcurrentTestImageKey options:0 context:nil cacheType:TMSDImageCacheTypeAll completion:nil];
    [cachesManager storeImage:[self testJPEGImage] imageData:nil forKey:kConcurrentTestImageKey cacheType:TMSDImageCacheTypeMemory completion:nil];
    [cachesManager removeImageForKey:kConcurrentTestImageKey cacheType:TMSDImageCacheTypeMemory completion:nil];
    [cachesManager clearWithCacheType:TMSDImageCacheTypeMemory completion:nil];
    
    // Check Logic works, check cache1(memory+JPEG) & cache2(disk+PNG) at the same time. Cache1(memory) is fast and hit.
    [cache1 storeImage:[self testJPEGImage] forKey:kConcurrentTestImageKey toDisk:NO completion:nil];
    [cache2 storeImage:[self testPNGImage] forKey:kConcurrentTestImageKey toDisk:YES completion:^{
        UIImage *memoryImage1 = [cache1 imageFromMemoryCacheForKey:kConcurrentTestImageKey];
        expect(memoryImage1).notTo.beNil();
        [cache2 removeImageFromMemoryForKey:kConcurrentTestImageKey];
        [cachesManager containsImageForKey:kConcurrentTestImageKey cacheType:TMSDImageCacheTypeAll completion:^(TMSDImageCacheType containsCacheType) {
            // Cache1 hit
            expect(containsCacheType).equal(TMSDImageCacheTypeMemory);
            [expectation fulfill];
        }];
    }];
    
    [self waitForExpectationsWithCommonTimeout];
}

- (void)test57TMSDImageCachesManagerOperationPolicySerial {
    XCTestExpectation *expectation = [self expectationWithDescription:@"TMSDImageCachesManager operation serial policy works"];
    TMSDImageCachesManager *cachesManager = [[TMSDImageCachesManager alloc] init];
    TMSDImageCache *cache1 = [[TMSDImageCache alloc] initWithNamespace:@"cache1"];
    TMSDImageCache *cache2 = [[TMSDImageCache alloc] initWithNamespace:@"cache2"];
    cachesManager.caches = @[cache1, cache2];
    
    [[NSFileManager defaultManager] removeItemAtPath:cache1.diskCachePath error:nil];
    [[NSFileManager defaultManager] removeItemAtPath:cache2.diskCachePath error:nil];
    
    NSString *kSerialTestImageKey = @"kSerialTestImageKey";
    
    // Serial
    // Check all serial op
    cachesManager.queryOperationPolicy = TMSDImageCachesManagerOperationPolicySerial;
    cachesManager.storeOperationPolicy = TMSDImageCachesManagerOperationPolicySerial;
    cachesManager.removeOperationPolicy = TMSDImageCachesManagerOperationPolicySerial;
    cachesManager.containsOperationPolicy = TMSDImageCachesManagerOperationPolicySerial;
    cachesManager.clearOperationPolicy = TMSDImageCachesManagerOperationPolicySerial;
    [cachesManager queryImageForKey:kSerialTestImageKey options:0 context:nil cacheType:TMSDImageCacheTypeAll completion:nil];
    [cachesManager storeImage:[self testJPEGImage] imageData:nil forKey:kSerialTestImageKey cacheType:TMSDImageCacheTypeMemory completion:nil];
    [cachesManager removeImageForKey:kSerialTestImageKey cacheType:TMSDImageCacheTypeMemory completion:nil];
    [cachesManager clearWithCacheType:TMSDImageCacheTypeMemory completion:nil];
    
    // Check Logic work, from cache2(disk+PNG) -> cache1(memory+JPEG). Cache2(disk) is slow but hit.
    [cache1 storeImage:[self testJPEGImage] forKey:kSerialTestImageKey toDisk:NO completion:nil];
    [cache2 storeImage:[self testPNGImage] forKey:kSerialTestImageKey toDisk:YES completion:^{
        UIImage *memoryImage1 = [cache1 imageFromMemoryCacheForKey:kSerialTestImageKey];
        expect(memoryImage1).notTo.beNil();
        [cache2 removeImageFromMemoryForKey:kSerialTestImageKey];
        [cachesManager containsImageForKey:kSerialTestImageKey cacheType:TMSDImageCacheTypeAll completion:^(TMSDImageCacheType containsCacheType) {
            // Cache2 hit
            expect(containsCacheType).equal(TMSDImageCacheTypeDisk);
            [expectation fulfill];
        }];
    }];
    
    [self waitForExpectationsWithCommonTimeout];
}

- (void)test58CustomImageCache {
    NSString *cachePath = [[self userCacheDirectory] stringByAppendingPathComponent:@"custom"];
    TMSDImageCacheConfig *config = [[TMSDImageCacheConfig alloc] init];
    TMSDWebImageTestCache *cache = [[TMSDWebImageTestCache alloc] initWithCachePath:cachePath config:config];
    expect(cache.memoryCache).notTo.beNil();
    expect(cache.diskCache).notTo.beNil();
    
    // Clear
    [cache clearWithCacheType:TMSDImageCacheTypeAll completion:nil];
    // Store
    UIImage *image1 = self.testJPEGImage;
    NSString *key1 = @"testJPEGImage";
    [cache storeImage:image1 imageData:nil forKey:key1 cacheType:TMSDImageCacheTypeAll completion:nil];
    // Contain
    [cache containsImageForKey:key1 cacheType:TMSDImageCacheTypeAll completion:^(TMSDImageCacheType containsCacheType) {
        expect(containsCacheType).equal(TMSDImageCacheTypeMemory);
    }];
    // Query
    [cache queryImageForKey:key1 options:0 context:nil cacheType:TMSDImageCacheTypeAll completion:^(UIImage * _Nullable image, NSData * _Nullable data, TMSDImageCacheType cacheType) {
        expect(image).equal(image1);
        expect(data).beNil();
        expect(cacheType).equal(TMSDImageCacheTypeMemory);
    }];
    // Remove
    [cache removeImageForKey:key1 cacheType:TMSDImageCacheTypeAll completion:nil];
    // Contain
    [cache containsImageForKey:key1 cacheType:TMSDImageCacheTypeAll completion:^(TMSDImageCacheType containsCacheType) {
        expect(containsCacheType).equal(TMSDImageCacheTypeNone);
    }];
    // Clear
    [cache clearWithCacheType:TMSDImageCacheTypeAll completion:nil];
    NSArray<NSString *> *cacheFiles = [cache.diskCache.fileManager contentsOfDirectoryAtPath:cachePath error:nil];
    expect(cacheFiles.count).equal(0);
}

#pragma mark Helper methods

- (UIImage *)testJPEGImage {
    static UIImage *reusableImage = nil;
    if (!reusableImage) {
        reusableImage = [[UIImage alloc] initWithContentsOfFile:[self testJPEGPath]];
    }
    return reusableImage;
}

- (UIImage *)testPNGImage {
    static UIImage *reusableImage = nil;
    if (!reusableImage) {
        reusableImage = [[UIImage alloc] initWithContentsOfFile:[self testPNGPath]];
    }
    return reusableImage;
}

- (UIImage *)testGIFImage {
    static UIImage *reusableImage = nil;
    if (!reusableImage) {
        NSData *data = [NSData dataWithContentsOfFile:[self testGIFPath]];
        reusableImage = [UIImage tmsd_imageWithData:data];
    }
    return reusableImage;
}

- (UIImage *)testAPNGImage {
    static UIImage *reusableImage = nil;
    if (!reusableImage) {
        NSData *data = [NSData dataWithContentsOfFile:[self testAPNGPath]];
        reusableImage = [UIImage tmsd_imageWithData:data];
    }
    return reusableImage;
}

- (NSString *)testJPEGPath {
    NSBundle *testBundle = [NSBundle bundleForClass:[self class]];
    return [testBundle pathForResource:@"TestImage" ofType:@"jpg"];
}

- (NSString *)testPNGPath {
    NSBundle *testBundle = [NSBundle bundleForClass:[self class]];
    return [testBundle pathForResource:@"TestImage" ofType:@"png"];
}

- (NSString *)testGIFPath {
    NSBundle *testBundle = [NSBundle bundleForClass:[self class]];
    NSString *testPath = [testBundle pathForResource:@"TestImage" ofType:@"gif"];
    return testPath;
}

- (NSString *)testAPNGPath {
    NSBundle *testBundle = [NSBundle bundleForClass:[self class]];
    NSString *testPath = [testBundle pathForResource:@"TestImageAnimated" ofType:@"apng"];
    return testPath;
}

- (nullable NSString *)userCacheDirectory {
    NSArray<NSString *> *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    return paths.firstObject;
}

@end
