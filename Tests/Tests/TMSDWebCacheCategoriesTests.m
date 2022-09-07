/*
 * This file is part of the TMSDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 * (c) Matt Galloway
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import <TMSDWebImage/TMSDTestCase.h>
#import <KVOController/KVOController.h>

@interface TMSDWebCacheCategoriesTests : TMSDTestCase

@property (nonatomic, strong) UIWindow *window;

@end

@implementation TMSDWebCacheCategoriesTests

- (void)testUIImageViewSetImageWithURL {
    XCTestExpectation *expectation = [self expectationWithDescription:@"UIImageView setImageWithURL"];
    
    UIImageView *imageView = [[UIImageView alloc] init];
    NSURL *originalImageURL = [NSURL URLWithString:kTestJPEGURL];
    [imageView tmsd_setImageWithURL:originalImageURL
                        completed:^(UIImage * _Nullable image, NSError * _Nullable error, TMSDImageCacheType cacheType, NSURL * _Nullable imageURL) {
                            expect(image).toNot.beNil();
                            expect(error).to.beNil();
                            expect(originalImageURL).to.equal(imageURL);
                            expect(imageView.image).to.equal(image);
                            [expectation fulfill];
                        }];
    expect(imageView.tmsd_imageURL).equal(originalImageURL);
    [self waitForExpectationsWithCommonTimeout];
}

- (void)testUIImageViewSetImageWithURLDiskSync {
    NSData *imageData = [NSData dataWithContentsOfFile:[self testJPEGPath]];
    
    // Ensure the image is cached in disk but not memory
    [TMSDImageCache.sharedImageCache removeImageFromMemoryForKey:kTestJPEGURL];
    [TMSDImageCache.sharedImageCache removeImageFromDiskForKey:kTestJPEGURL];
    [TMSDImageCache.sharedImageCache storeImageDataToDisk:imageData forKey:kTestJPEGURL];
    
    UIImageView *imageView = [[UIImageView alloc] init];
    NSURL *originalImageURL = [NSURL URLWithString:kTestJPEGURL];
    
    [imageView tmsd_setImageWithURL:originalImageURL
                 placeholderImage:nil
                          options:TMSDWebImageQueryDiskDataSync
                        completed:^(UIImage * _Nullable image, NSError * _Nullable error, TMSDImageCacheType cacheType, NSURL * _Nullable imageURL) {
                            expect(image).toNot.beNil();
                            expect(error).to.beNil();
                            expect(originalImageURL).to.equal(imageURL);
                            expect(imageView.image).to.equal(image);
                        }];
    expect(imageView.tmsd_imageURL).equal(originalImageURL);
    expect(imageView.image).toNot.beNil();
}

#if TMSD_UIKIT
- (void)testUIImageViewSetHighlightedImageWithURL {
    XCTestExpectation *expectation = [self expectationWithDescription:@"UIImageView setHighlightedImageWithURL"];
    
    UIImageView *imageView = [[UIImageView alloc] init];
    NSURL *originalImageURL = [NSURL URLWithString:kTestJPEGURL];
    [imageView tmsd_setHighlightedImageWithURL:originalImageURL
                                   completed:^(UIImage * _Nullable image, NSError * _Nullable error, TMSDImageCacheType cacheType, NSURL * _Nullable imageURL) {
                                       expect(image).toNot.beNil();
                                       expect(error).to.beNil();
                                       expect(originalImageURL).to.equal(imageURL);
                                       expect(imageView.highlightedImage).to.equal(image);
                                       [expectation fulfill];
                                   }];
    [self waitForExpectationsWithCommonTimeout];
}
#endif

- (void)testMKAnnotationViewSetImageWithURL {
    XCTestExpectation *expectation = [self expectationWithDescription:@"MKAnnotationView setImageWithURL"];
    
    MKAnnotationView *annotationView = [[MKAnnotationView alloc] init];
    NSURL *originalImageURL = [NSURL URLWithString:kTestJPEGURL];
    [annotationView tmsd_setImageWithURL:originalImageURL
                             completed:^(UIImage * _Nullable image, NSError * _Nullable error, TMSDImageCacheType cacheType, NSURL * _Nullable imageURL) {
                                 expect(image).toNot.beNil();
                                 expect(error).to.beNil();
                                 expect(originalImageURL).to.equal(imageURL);
                                 expect(annotationView.image).to.equal(image);
                                 [expectation fulfill];
                             }];
    [self waitForExpectationsWithCommonTimeout];
}

#if TMSD_UIKIT
- (void)testUIButtonSetImageWithURLNormalState {
    XCTestExpectation *expectation = [self expectationWithDescription:@"UIButton setImageWithURL normalState"];
    
    UIButton *button = [[UIButton alloc] init];
    NSURL *originalImageURL = [NSURL URLWithString:kTestJPEGURL];
    [button tmsd_setImageWithURL:originalImageURL
                      forState:UIControlStateNormal
                     completed:^(UIImage * _Nullable image, NSError * _Nullable error, TMSDImageCacheType cacheType, NSURL * _Nullable imageURL) {
                         expect(image).toNot.beNil();
                         expect(error).to.beNil();
                         expect(originalImageURL).to.equal(imageURL);
                         expect([button imageForState:UIControlStateNormal]).to.equal(image);
                         [expectation fulfill];
                     }];
    [self waitForExpectationsWithCommonTimeout];
}

- (void)testUIButtonSetImageWithURLHighlightedState {
    XCTestExpectation *expectation = [self expectationWithDescription:@"UIButton setImageWithURL highlightedState"];
    
    UIButton *button = [[UIButton alloc] init];
    NSURL *originalImageURL = [NSURL URLWithString:kTestJPEGURL];
    [button tmsd_setImageWithURL:originalImageURL
                      forState:UIControlStateHighlighted
                     completed:^(UIImage * _Nullable image, NSError * _Nullable error, TMSDImageCacheType cacheType, NSURL * _Nullable imageURL) {
                         expect(image).toNot.beNil();
                         expect(error).to.beNil();
                         expect(originalImageURL).to.equal(imageURL);
                         expect([button imageForState:UIControlStateHighlighted]).to.equal(image);
                         [expectation fulfill];
                     }];
    [self waitForExpectationsWithCommonTimeout];
}

- (void)testUIButtonSetBackgroundImageWithURLNormalState {
    XCTestExpectation *expectation = [self expectationWithDescription:@"UIButton setBackgroundImageWithURL normalState"];
    
    UIButton *button = [[UIButton alloc] init];
    NSURL *originalImageURL = [NSURL URLWithString:kTestJPEGURL];
    [button tmsd_setBackgroundImageWithURL:originalImageURL
                                forState:UIControlStateNormal
                               completed:^(UIImage * _Nullable image, NSError * _Nullable error, TMSDImageCacheType cacheType, NSURL * _Nullable imageURL) {
                                   expect(image).toNot.beNil();
                                   expect(error).to.beNil();
                                   expect(originalImageURL).to.equal(imageURL);
                                   expect([button backgroundImageForState:UIControlStateNormal]).to.equal(image);
                                   [expectation fulfill];
                               }];
    [self waitForExpectationsWithCommonTimeout];
}

- (void)testUIButtonBackgroundImageCancelCurrentImageLoad {
    UIButton *button = [[UIButton alloc] init];
    NSURL *originalImageURL = [NSURL URLWithString:kTestJPEGURL];
    [button tmsd_setBackgroundImageWithURL:originalImageURL forState:UIControlStateNormal];
    [button tmsd_cancelBackgroundImageLoadForState:UIControlStateNormal];
    NSString *backgroundImageOperationKey = [self testBackgroundImageOperationKeyForState:UIControlStateNormal];
    expect([button tmsd_imageLoadOperationForKey:backgroundImageOperationKey]).beNil();
}

#endif

#if TMSD_MAC
- (void)testNSButtonSetImageWithURL {
    XCTestExpectation *expectation = [self expectationWithDescription:@"NSButton setImageWithURL"];
    
    NSButton *button = [[NSButton alloc] init];
    NSURL *originalImageURL = [NSURL URLWithString:kTestJPEGURL];
    [button tmsd_setImageWithURL:originalImageURL
                     completed:^(UIImage * _Nullable image, NSError * _Nullable error, TMSDImageCacheType cacheType, NSURL * _Nullable imageURL) {
                         expect(image).toNot.beNil();
                         expect(error).to.beNil();
                         expect(originalImageURL).to.equal(imageURL);
                         expect(button.image).to.equal(image);
                         [expectation fulfill];
                     }];
    [self waitForExpectationsWithCommonTimeout];
}

- (void)testNSButtonSetAlternateImageWithURL {
    XCTestExpectation *expectation = [self expectationWithDescription:@"NSButton setAlternateImageWithURL"];
    
    NSButton *button = [[NSButton alloc] init];
    NSURL *originalImageURL = [NSURL URLWithString:kTestJPEGURL];
    [button tmsd_setAlternateImageWithURL:originalImageURL
                              completed:^(UIImage * _Nullable image, NSError * _Nullable error, TMSDImageCacheType cacheType, NSURL * _Nullable imageURL) {
                                  expect(image).toNot.beNil();
                                  expect(error).to.beNil();
                                  expect(originalImageURL).to.equal(imageURL);
                                  expect(button.alternateImage).to.equal(image);
                                  [expectation fulfill];
                              }];
    [self waitForExpectationsWithCommonTimeout];
}
#endif

- (void)testUIViewInternalSetImageWithURL {
    XCTestExpectation *expectation = [self expectationWithDescription:@"UIView internalSetImageWithURL"];
    
    UIView *view = [[UIView alloc] init];
#if TMSD_MAC
    view.wantsLayer = YES;
#endif
    NSURL *originalImageURL = [NSURL URLWithString:kTestJPEGURL];
    UIImage *placeholder = [[UIImage alloc] initWithContentsOfFile:[self testJPEGPath]];
    [view tmsd_internalSetImageWithURL:originalImageURL
                    placeholderImage:placeholder
                             options:0
                             context:nil
                       setImageBlock:^(UIImage * _Nullable image, NSData * _Nullable imageData, TMSDImageCacheType cacheType, NSURL * _Nullable imageURL) {
                           if (!imageData && cacheType == TMSDImageCacheTypeNone) {
                               // placeholder
                               expect(image).to.equal(placeholder);
                           } else {
                               // cache or download
                               expect(image).toNot.beNil();
                           }
                           view.layer.contents = (__bridge id _Nullable)(image.CGImage);
                       }
                            progress:nil
                           completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, TMSDImageCacheType cacheType, BOOL finished, NSURL * _Nullable imageURL) {
                               expect(image).toNot.beNil();
                               expect(error).to.beNil();
                               expect(originalImageURL).to.equal(imageURL);
                               expect((__bridge CGImageRef)view.layer.contents == image.CGImage).to.beTruthy();
                               [expectation fulfill];
                           }];
    [self waitForExpectationsWithCommonTimeout];
}

- (void)testUIViewCancelWithDelayPlaceholderShouldCallbackOnceBeforeSecond {
    XCTestExpectation *expectation1 = [self expectationWithDescription:@"UIView internalSetImageWithURL call 1"];
    XCTestExpectation *expectation2 = [self expectationWithDescription:@"UIView internalSetImageWithURL call 2"];
    
    UIView *imageView = [[UIView alloc] init];
    NSURL *originalImageURL = [NSURL URLWithString:kTestJPEGURL];
    [TMSDImageCache.sharedImageCache removeImageFromDiskForKey:kTestJPEGURL];
    [TMSDImageCache.sharedImageCache removeImageFromMemoryForKey:kTestJPEGURL];
    
    __block NSUInteger calledSetImageTimes = 0;
    __block NSUInteger calledSetImageTimes2 = 0;
    NSString *operationKey = NSUUID.UUID.UUIDString;
    UIImage *placeholder1 = UIImage.new;
    id<TMSDWebImageOperation> op1 = [imageView tmsd_internalSetImageWithURL:originalImageURL placeholderImage:placeholder1 options:TMSDWebImageDelayPlaceholder context:@{ TMSDWebImageContextSetImageOperationKey:operationKey} setImageBlock:^(UIImage * _Nullable image, NSData * _Nullable imageData, TMSDImageCacheType cacheType, NSURL * _Nullable imageURL) {
        // Should called before second query (We changed the cache callback in sync when cancelled)
        expect(calledSetImageTimes2).equal(0);
        calledSetImageTimes++;
    } progress:nil completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, TMSDImageCacheType cacheType, BOOL finished, NSURL * _Nullable imageURL) {
        if (calledSetImageTimes == 1) {
            [expectation1 fulfill];
        }
    }];
    [op1 cancel];
    
    UIImage *placeholder2 = UIImage.new;
    [imageView tmsd_internalSetImageWithURL:originalImageURL placeholderImage:placeholder2 options:0 context:@{ TMSDWebImageContextSetImageOperationKey:operationKey} setImageBlock:^(UIImage * _Nullable image, NSData * _Nullable imageData, TMSDImageCacheType cacheType, NSURL * _Nullable imageURL) {
        if (calledSetImageTimes2 == 0) {
            expect(image).equal(placeholder2);
        } else {
            expect(image).notTo.beNil();
        }
        calledSetImageTimes2++;
    } progress:nil completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, TMSDImageCacheType cacheType, BOOL finished, NSURL * _Nullable imageURL) {
        if (calledSetImageTimes2 == 2) {
            [expectation2 fulfill];
        }
    }];
    
    [self waitForExpectationsWithCommonTimeout];
}

- (void)testUIViewCancelWithoutDelayPlaceholderShouldCallbackOnceBeforeSecond {
    XCTestExpectation *expectation1 = [self expectationWithDescription:@"UIView internalSetImageWithURL call 1"];
    XCTestExpectation *expectation2 = [self expectationWithDescription:@"UIView internalSetImageWithURL call 2"];
    
    UIView *imageView = [[UIView alloc] init];
    NSURL *originalImageURL = [NSURL URLWithString:kTestJPEGURL];
    [TMSDImageCache.sharedImageCache removeImageFromDiskForKey:kTestJPEGURL];
    [TMSDImageCache.sharedImageCache removeImageFromMemoryForKey:kTestJPEGURL];
    
    __block NSUInteger calledSetImageTimes = 0;
    __block NSUInteger calledSetImageTimes2 = 0;
    NSString *operationKey = NSUUID.UUID.UUIDString;
    UIImage *placeholder1 = UIImage.new;
    id<TMSDWebImageOperation> op1 = [imageView tmsd_internalSetImageWithURL:originalImageURL placeholderImage:placeholder1 options:0 context:@{ TMSDWebImageContextSetImageOperationKey:operationKey} setImageBlock:^(UIImage * _Nullable image, NSData * _Nullable imageData, TMSDImageCacheType cacheType, NSURL * _Nullable imageURL) {
        // Should called before second query (We changed the cache callback in sync when cancelled)
        expect(calledSetImageTimes2).equal(0);
        calledSetImageTimes++;
    } progress:nil completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, TMSDImageCacheType cacheType, BOOL finished, NSURL * _Nullable imageURL) {
        if (calledSetImageTimes == 1) {
            [expectation1 fulfill];
        }
    }];
    [op1 cancel];
    
    UIImage *placeholder2 = UIImage.new;
    [imageView tmsd_internalSetImageWithURL:originalImageURL placeholderImage:placeholder2 options:0 context:@{ TMSDWebImageContextSetImageOperationKey:operationKey} setImageBlock:^(UIImage * _Nullable image, NSData * _Nullable imageData, TMSDImageCacheType cacheType, NSURL * _Nullable imageURL) {
        if (calledSetImageTimes2 == 0) {
            expect(image).equal(placeholder2);
        } else {
            expect(image).notTo.beNil();
        }
        calledSetImageTimes2++;
    } progress:nil completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, TMSDImageCacheType cacheType, BOOL finished, NSURL * _Nullable imageURL) {
        if (calledSetImageTimes2 == 2) {
            [expectation2 fulfill];
        }
    }];
    
    [self waitForExpectationsWithCommonTimeout];
}

- (void)testUIViewCancelCurrentImageLoad {
    UIView *imageView = [[UIView alloc] init];
    NSURL *originalImageURL = [NSURL URLWithString:kTestJPEGURL];
    [TMSDImageCache.sharedImageCache removeImageFromDiskForKey:kTestJPEGURL];
    [TMSDImageCache.sharedImageCache removeImageFromMemoryForKey:kTestJPEGURL];
    [imageView tmsd_internalSetImageWithURL:originalImageURL placeholderImage:nil options:0 context:nil setImageBlock:nil progress:nil completed:nil];
    [imageView tmsd_cancelCurrentImageLoad];
    NSString *operationKey = NSStringFromClass(UIView.class);
    expect(imageView.tmsd_latestOperationKey).beNil();
    expect([imageView tmsd_imageLoadOperationForKey:operationKey]).beNil();
}

- (void)testUIViewCancelCurrentImageLoadWithTransition {
    UIView *imageView = [[UIView alloc] init];
    NSURL *firstImageUrl = [NSURL URLWithString:kTestJPEGURL];
    NSURL *secondImageUrl = [NSURL URLWithString:kTestPNGURL];

    // First, reset our caches
    [TMSDImageCache.sharedImageCache removeImageFromDiskForKey:kTestJPEGURL];
    [TMSDImageCache.sharedImageCache removeImageFromMemoryForKey:kTestPNGURL];

    // Next, lets put our second image into memory, so that the next time
    // we load it, it will come from memory, and thus shouldUseTransition will be NO
    XCTestExpectation *firstLoadExpectation = [self expectationWithDescription:@"First image loaded"];

    [imageView tmsd_internalSetImageWithURL:secondImageUrl placeholderImage:nil options:0 context:nil setImageBlock:nil progress:nil completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, TMSDImageCacheType cacheType, BOOL finished, NSURL * _Nullable imageURL) {
        [firstLoadExpectation fulfill];
    }];

    [self waitForExpectations:@[firstLoadExpectation]
                      timeout:5.0];

    // Now, lets load a new image using a transition
    XCTestExpectation *secondLoadExpectation = [self expectationWithDescription:@"Second image loaded"];
    XCTestExpectation *transitionPreparesExpectation = [self expectationWithDescription:@"Transition prepares"];

    // Build a custom transition with a completion block that
    // we do not expect to be called, because we cancel in the
    // middle of a transition
    XCTestExpectation *transitionCompletionExpecation = [self expectationWithDescription:@"Transition completed"];
    transitionCompletionExpecation.inverted = YES;

    TMSDWebImageTransition *customTransition = [TMSDWebImageTransition new];
    customTransition.duration = 1.0;
    customTransition.prepares = ^(__kindof UIView * _Nonnull view, UIImage * _Nullable image, NSData * _Nullable imageData, TMSDImageCacheType cacheType, NSURL * _Nullable imageURL) {
        [transitionPreparesExpectation fulfill];
    };
    customTransition.completion = ^(BOOL finished) {
        [transitionCompletionExpecation fulfill];
    };

    // Now, load our first image URL (maybe as part of a UICollectionView)
    // We use a custom context to ensure a unique ImageOperationKey for every load
    // that is requested
    NSMutableDictionary *context = [NSMutableDictionary new];
    context[TMSDWebImageContextSetImageOperationKey] = firstImageUrl.absoluteString;

    imageView.tmsd_imageTransition = customTransition;
    [imageView tmsd_internalSetImageWithURL:firstImageUrl placeholderImage:nil options:0 context:context setImageBlock:nil progress:nil completed:nil];
    [self waitForExpectations:@[transitionPreparesExpectation] timeout:5.0];

    // At this point, our transition has started, and so we cancel the load operation,
    // perhaps as a result of a call to `prepareForReuse` in a UICollectionViewCell
    [imageView tmsd_cancelCurrentImageLoad];

    // Now, we update our context's imageOperationKey and URL, perhaps
    // because of a re-use of a UICollectionViewCell. In this case,
    // we are assigning an image URL that is already present in the
    // memory cache
    context[TMSDWebImageContextSetImageOperationKey] = secondImageUrl.absoluteString;
    [imageView tmsd_internalSetImageWithURL:secondImageUrl placeholderImage:nil options:0 context:context setImageBlock:nil progress:nil completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, TMSDImageCacheType cacheType, BOOL finished, NSURL * _Nullable imageURL) {

        [secondLoadExpectation fulfill];
    }];

    // The original load operation's transitionCompletionExpecation should never
    // be called (it has been inverted, above)
    [self waitForExpectations:@[secondLoadExpectation, transitionCompletionExpecation]
                      timeout:2.0];
}

- (void)testUIViewCancelCallbackWithError {
    XCTestExpectation *expectation = [self expectationWithDescription:@"UIView internalSetImageWithURL cancel callback error"];
    
    UIView *imageView = [[UIView alloc] init];
    NSURL *originalImageURL = [NSURL URLWithString:kTestJPEGURL];
    [TMSDImageCache.sharedImageCache removeImageFromDiskForKey:kTestJPEGURL];
    [TMSDImageCache.sharedImageCache removeImageFromMemoryForKey:kTestJPEGURL];
    [imageView tmsd_internalSetImageWithURL:originalImageURL placeholderImage:nil options:0 context:nil setImageBlock:nil progress:nil completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, TMSDImageCacheType cacheType, BOOL finished, NSURL * _Nullable imageURL) {
        expect(error).notTo.beNil();
        expect(error.code).equal(TMSDWebImageErrorCancelled);
        [expectation fulfill];
    }];
    [imageView tmsd_cancelCurrentImageLoad];
    
    [self waitForExpectationsWithCommonTimeout];
}

- (void)testUIViewImageProgressKVOWork {
    XCTestExpectation *expectation = [self expectationWithDescription:@"UIView imageProgressKVO failed"];
    UIView *view = [[UIView alloc] init];
    NSURL *originalImageURL = [NSURL URLWithString:kTestJPEGURL];
    
    [self.KVOController observe:view.tmsd_imageProgress keyPath:NSStringFromSelector(@selector(fractionCompleted)) options:NSKeyValueObservingOptionNew block:^(id  _Nullable observer, id  _Nonnull object, NSDictionary<NSString *,id> * _Nonnull change) {
        NSProgress *progress = object;
        NSNumber *completedValue = change[NSKeyValueChangeNewKey];
        expect(progress.fractionCompleted).equal(completedValue.doubleValue);
        // mark that KVO is called
        [progress setUserInfoObject:@(YES) forKey:NSStringFromSelector(@selector(testUIViewImageProgressKVOWork))];
    }];
    
    // Clear the disk cache to force download from network
    [[TMSDImageCache sharedImageCache] removeImageForKey:kTestJPEGURL withCompletion:^{
        [view tmsd_internalSetImageWithURL:originalImageURL placeholderImage:nil options:0 context:nil setImageBlock:nil progress:nil completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, TMSDImageCacheType cacheType, BOOL finished, NSURL * _Nullable imageURL) {
            expect(view.tmsd_imageProgress.fractionCompleted).equal(1.0);
            expect([view.tmsd_imageProgress.userInfo[NSStringFromSelector(_cmd)] boolValue]).equal(YES);
            [expectation fulfill];
        }];
    }];
    [self waitForExpectationsWithCommonTimeout];
}

- (void)testUIViewTransitionFromNetworkWork {
    XCTestExpectation *expectation = [self expectationWithDescription:@"UIView transition from network does not work"];
    
    // Attach a window, or CALayer will not submit drawing
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 50, 50)];
    // Cover each convenience method
    imageView.tmsd_imageTransition = TMSDWebImageTransition.fadeTransition;
    imageView.tmsd_imageTransition = TMSDWebImageTransition.flipFromTopTransition;
    imageView.tmsd_imageTransition = TMSDWebImageTransition.flipFromLeftTransition;
    imageView.tmsd_imageTransition = TMSDWebImageTransition.flipFromBottomTransition;
    imageView.tmsd_imageTransition = TMSDWebImageTransition.flipFromRightTransition;
    imageView.tmsd_imageTransition = TMSDWebImageTransition.curlUpTransition;
    imageView.tmsd_imageTransition = TMSDWebImageTransition.curlDownTransition;
    imageView.tmsd_imageTransition.duration = 1;
    
#if TMSD_UIKIT
    [self.window addSubview:imageView];
#else
    imageView.wantsLayer = YES;
    [self.window.contentView addSubview:imageView];
#endif
    
    UIImage *placeholder = [[UIImage alloc] initWithContentsOfFile:[self testJPEGPath]];
    
    NSURL *originalImageURL = [NSURL URLWithString:kTestJPEGURL];
    __weak typeof(imageView) wimageView = imageView;
    [imageView tmsd_setImageWithURL:originalImageURL
                 placeholderImage:placeholder
                          options:TMSDWebImageForceTransition
                        completed:^(UIImage * _Nullable image, NSError * _Nullable error, TMSDImageCacheType cacheType, NSURL * _Nullable imageURL) {
                            __strong typeof(wimageView) simageView = imageView;
                            // Delay to let CALayer commit the transition in next runloop
                            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, kMinDelayNanosecond), dispatch_get_main_queue(), ^{
                                // Check current view contains layer animation
                                NSArray *animationKeys = simageView.layer.animationKeys;
                                expect(animationKeys.count).beGreaterThan(0);
                                [expectation fulfill];
                            });
                        }];
    
    [self waitForExpectationsWithCommonTimeout];
}

- (void)testUIViewTransitionFromDiskWork {
    XCTestExpectation *expectation = [self expectationWithDescription:@"UIView transition from disk does not work"];
    
    // Attach a window, or CALayer will not submit drawing
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 50, 50)];
    imageView.tmsd_imageTransition = TMSDWebImageTransition.fadeTransition;
    imageView.tmsd_imageTransition.duration = 1;
    
#if TMSD_UIKIT
    [self.window addSubview:imageView];
#else
    imageView.wantsLayer = YES;
    [self.window.contentView addSubview:imageView];
#endif
    
    NSData *imageData = [NSData dataWithContentsOfFile:[self testJPEGPath]];
    UIImage *placeholder = [[UIImage alloc] initWithData:imageData];
    
    // Ensure the image is cached in disk but not memory
    [TMSDImageCache.sharedImageCache removeImageFromMemoryForKey:kTestJPEGURL];
    [TMSDImageCache.sharedImageCache removeImageFromDiskForKey:kTestJPEGURL];
    [TMSDImageCache.sharedImageCache storeImageDataToDisk:imageData forKey:kTestJPEGURL];
    
    NSURL *originalImageURL = [NSURL URLWithString:kTestJPEGURL];
    __weak typeof(imageView) wimageView = imageView;
    [imageView tmsd_setImageWithURL:originalImageURL
                 placeholderImage:placeholder
                          options:TMSDWebImageFromCacheOnly // Ensure we queired from disk cache
                        completed:^(UIImage * _Nullable image, NSError * _Nullable error, TMSDImageCacheType cacheType, NSURL * _Nullable imageURL) {
                            [TMSDImageCache.sharedImageCache removeImageFromMemoryForKey:kTestJPEGURL];
                            [TMSDImageCache.sharedImageCache removeImageFromDiskForKey:kTestJPEGURL];
                            __strong typeof(wimageView) simageView = imageView;
                            // Delay to let CALayer commit the transition in next runloop
                            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, kMinDelayNanosecond), dispatch_get_main_queue(), ^{
                                // Check current view contains layer animation
                                NSArray *animationKeys = simageView.layer.animationKeys;
                                expect(animationKeys.count).beGreaterThan(0);
                                [expectation fulfill];
                            });
                        }];
    
    [self waitForExpectationsWithCommonTimeout];
}

- (void)testUIViewIndicatorWork {
    XCTestExpectation *expectation = [self expectationWithDescription:@"UIView indicator does not work"];
    
    UIImageView *imageView = [[UIImageView alloc] init];
    imageView.tmsd_imageIndicator = TMSDWebImageActivityIndicator.grayIndicator;
    // Cover each convience method, finally use progress indicator for test
    imageView.tmsd_imageIndicator = TMSDWebImageActivityIndicator.grayLargeIndicator;
    imageView.tmsd_imageIndicator = TMSDWebImageActivityIndicator.whiteIndicator;
    imageView.tmsd_imageIndicator = TMSDWebImageActivityIndicator.whiteLargeIndicator;
#if TMSD_IOS
    imageView.tmsd_imageIndicator = TMSDWebImageProgressIndicator.barIndicator;
#endif
    imageView.tmsd_imageIndicator = TMSDWebImageProgressIndicator.defaultIndicator;
    // Test setter trigger removeFromSuperView
    expect(imageView.subviews.count).equal(1);
    
    NSURL *originalImageURL = [NSURL URLWithString:kTestJPEGURL];
    __weak typeof(imageView) wimageView = imageView;
    [imageView tmsd_setImageWithURL:originalImageURL
                 placeholderImage:nil options:TMSDWebImageFromLoaderOnly progress:^(NSInteger receivedSize, NSInteger expectedSize, NSURL * _Nullable targetURL) {
                     dispatch_async(dispatch_get_main_queue(), ^{
                         __strong typeof(wimageView) simageView = imageView;
                         UIView *indicatorView = simageView.subviews.firstObject;
                         expect(indicatorView).equal(simageView.tmsd_imageIndicator.indicatorView);
                         
                         if (receivedSize <= 0 || expectedSize <= 0) {
                             return;
                         }
                         
                         // Base on current implementation, since we dispatch the progressBlock to main queue, the indicator's progress state should be synchonized
                         double progress = 0;
                         double imageProgress = (double)receivedSize / (double)expectedSize;
#if TMSD_UIKIT
                         progress = ((UIProgressView *)simageView.tmsd_imageIndicator.indicatorView).progress;
#else
                         progress = ((NSProgressIndicator *)simageView.tmsd_imageIndicator.indicatorView).doubleValue / 100;
#endif
                         expect(progress).equal(imageProgress);
                     });
                 } completed:^(UIImage * _Nullable image, NSError * _Nullable error, TMSDImageCacheType cacheType, NSURL * _Nullable imageURL) {
                     __strong typeof(wimageView) simageView = imageView;
                     double progress = 0;
#if TMSD_UIKIT
                     progress = ((UIProgressView *)simageView.tmsd_imageIndicator.indicatorView).progress;
#else
                     progress = ((NSProgressIndicator *)simageView.tmsd_imageIndicator.indicatorView).doubleValue / 100;
#endif
                     // Finish progress is 1
                     expect(progress).equal(1);
                     [expectation fulfill];
                 }];
    
    [self waitForExpectationsWithCommonTimeout];
}

- (void)testUIViewOperationKeyContextWorks {
    XCTestExpectation *expectation = [self expectationWithDescription:@"UIView operation key context should pass through"];
    
    UIView *view = [[UIView alloc] init];
    NSURL *originalImageURL = [NSURL URLWithString:kTestJPEGURL];
    TMSDWebImageManager *customManager = [[TMSDWebImageManager alloc] initWithCache:TMSDImageCachesManager.sharedManager loader:TMSDImageLoadersManager.sharedManager];
    customManager.optionsProcessor = [TMSDWebImageOptionsProcessor optionsProcessorWithBlock:^TMSDWebImageOptionsResult * _Nullable(NSURL * _Nullable url, TMSDWebImageOptions options, TMSDWebImageContext * _Nullable context) {
        // expect manager does not exist, avoid retain cycle
        expect(context[TMSDWebImageContextCustomManager]).beNil();
        // expect operation key to be the image view class
        expect(context[TMSDWebImageContextSetImageOperationKey]).equal(NSStringFromClass(view.class));
        return [[TMSDWebImageOptionsResult alloc] initWithOptions:options context:context];
    }];
    [view tmsd_internalSetImageWithURL:originalImageURL
                    placeholderImage:nil
                             options:0
                             context:@{TMSDWebImageContextCustomManager: customManager}
                       setImageBlock:nil
                            progress:nil
                           completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, TMSDImageCacheType cacheType, BOOL finished, NSURL * _Nullable imageURL) {
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithCommonTimeout];
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

- (NSString *)testJPEGPath {
    NSBundle *testBundle = [NSBundle bundleForClass:[self class]];
    return [testBundle pathForResource:@"TestImage" ofType:@"jpg"];
}

#if TMSD_UIKIT
- (NSString *)testBackgroundImageOperationKeyForState:(UIControlState)state {
    return [NSString stringWithFormat:@"UIButtonBackgroundImageOperation%lu", (unsigned long)state];
}
#endif

@end
