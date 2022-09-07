/*
 * This file is part of the TMSDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import <TMSDWebImage/UIView+WebCache.h>
#import "objc/runtime.h"
#import <TMSDWebImage/UIView+WebCacheOperation.h>
#import <TMSDWebImage/TMSDWebImageError.h>
#import <TMSDWebImage/TMSDInternalMacros.h>
#import <TMSDWebImage/TMSDWebImageTransitionInternal.h>
#import <TMSDWebImage/TMSDImageCache.h>

const int64_t TMSDWebImageProgressUnitCountUnknown = 1LL;

@implementation UIView (TMSDWebCache)

- (nullable NSURL *)tmsd_imageURL {
    return objc_getAssociatedObject(self, @selector(tmsd_imageURL));
}

- (void)setTmsd_imageURL:(NSURL * _Nullable)tmsd_imageURL {
    objc_setAssociatedObject(self, @selector(tmsd_imageURL), tmsd_imageURL, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (nullable NSString *)tmsd_latestOperationKey {
    return objc_getAssociatedObject(self, @selector(tmsd_latestOperationKey));
}

- (void)setTmsd_latestOperationKey:(NSString * _Nullable)tmsd_latestOperationKey {
    objc_setAssociatedObject(self, @selector(tmsd_latestOperationKey), tmsd_latestOperationKey, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (NSProgress *)tmsd_imageProgress {
    NSProgress *progress = objc_getAssociatedObject(self, @selector(tmsd_imageProgress));
    if (!progress) {
        progress = [[NSProgress alloc] initWithParent:nil userInfo:nil];
        self.tmsd_imageProgress = progress;
    }
    return progress;
}

- (void)setTmsd_imageProgress:(NSProgress *)tmsd_imageProgress {
    objc_setAssociatedObject(self, @selector(tmsd_imageProgress), tmsd_imageProgress, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (nullable id<TMSDWebImageOperation>)tmsd_internalSetImageWithURL:(nullable NSURL *)url
                                              placeholderImage:(nullable UIImage *)placeholder
                                                       options:(TMSDWebImageOptions)options
                                                       context:(nullable TMSDWebImageContext *)context
                                                 setImageBlock:(nullable TMSDSetImageBlock)setImageBlock
                                                      progress:(nullable TMSDImageLoaderProgressBlock)progressBlock
                                                     completed:(nullable TMSDInternalCompletionBlock)completedBlock {
    if (context) {
        // copy to avoid mutable object
        context = [context copy];
    } else {
        context = [NSDictionary dictionary];
    }
    NSString *validOperationKey = context[TMSDWebImageContextSetImageOperationKey];
    if (!validOperationKey) {
        // pass through the operation key to downstream, which can used for tracing operation or image view class
        validOperationKey = NSStringFromClass([self class]);
        TMSDWebImageMutableContext *mutableContext = [context mutableCopy];
        mutableContext[TMSDWebImageContextSetImageOperationKey] = validOperationKey;
        context = [mutableContext copy];
    }
    self.tmsd_latestOperationKey = validOperationKey;
    [self tmsd_cancelImageLoadOperationWithKey:validOperationKey];
    self.tmsd_imageURL = url;
    
    TMSDWebImageManager *manager = context[TMSDWebImageContextCustomManager];
    if (!manager) {
        manager = [TMSDWebImageManager sharedManager];
    } else {
        // remove this manager to avoid retain cycle (manger -> loader -> operation -> context -> manager)
        TMSDWebImageMutableContext *mutableContext = [context mutableCopy];
        mutableContext[TMSDWebImageContextCustomManager] = nil;
        context = [mutableContext copy];
    }
    
    BOOL shouldUseWeakCache = NO;
    if ([manager.imageCache isKindOfClass:TMSDImageCache.class]) {
        shouldUseWeakCache = ((TMSDImageCache *)manager.imageCache).config.shouldUseWeakMemoryCache;
    }
    if (!(options & TMSDWebImageDelayPlaceholder)) {
        if (shouldUseWeakCache) {
            NSString *key = [manager cacheKeyForURL:url context:context];
            // call memory cache to trigger weak cache sync logic, ignore the return value and go on normal query
            // this unfortunately will cause twice memory cache query, but it's fast enough
            // in the future the weak cache feature may be re-design or removed
            [((TMSDImageCache *)manager.imageCache) imageFromMemoryCacheForKey:key];
        }
        dispatch_main_async_safe(^{
            [self tmsd_setImage:placeholder imageData:nil basedOnClassOrViaCustomSetImageBlock:setImageBlock cacheType:TMSDImageCacheTypeNone imageURL:url];
        });
    }
    
    id <TMSDWebImageOperation> operation = nil;
    
    if (url) {
        // reset the progress
        NSProgress *imageProgress = objc_getAssociatedObject(self, @selector(tmsd_imageProgress));
        if (imageProgress) {
            imageProgress.totalUnitCount = 0;
            imageProgress.completedUnitCount = 0;
        }
        
#if TMSD_UIKIT || TMSD_MAC
        // check and start image indicator
        [self tmsd_startImageIndicator];
        id<TMSDWebImageIndicator> imageIndicator = self.tmsd_imageIndicator;
#endif
        
        TMSDImageLoaderProgressBlock combinedProgressBlock = ^(NSInteger receivedSize, NSInteger expectedSize, NSURL * _Nullable targetURL) {
            if (imageProgress) {
                imageProgress.totalUnitCount = expectedSize;
                imageProgress.completedUnitCount = receivedSize;
            }
#if TMSD_UIKIT || TMSD_MAC
            if ([imageIndicator respondsToSelector:@selector(updateIndicatorProgress:)]) {
                double progress = 0;
                if (expectedSize != 0) {
                    progress = (double)receivedSize / expectedSize;
                }
                progress = MAX(MIN(progress, 1), 0); // 0.0 - 1.0
                dispatch_async(dispatch_get_main_queue(), ^{
                    [imageIndicator updateIndicatorProgress:progress];
                });
            }
#endif
            if (progressBlock) {
                progressBlock(receivedSize, expectedSize, targetURL);
            }
        };
        @weakify(self);
        operation = [manager loadImageWithURL:url options:options context:context progress:combinedProgressBlock completed:^(UIImage *image, NSData *data, NSError *error, TMSDImageCacheType cacheType, BOOL finished, NSURL *imageURL) {
            @strongify(self);
            if (!self) { return; }
            // if the progress not been updated, mark it to complete state
            if (imageProgress && finished && !error && imageProgress.totalUnitCount == 0 && imageProgress.completedUnitCount == 0) {
                imageProgress.totalUnitCount = TMSDWebImageProgressUnitCountUnknown;
                imageProgress.completedUnitCount = TMSDWebImageProgressUnitCountUnknown;
            }
            
#if TMSD_UIKIT || TMSD_MAC
            // check and stop image indicator
            if (finished) {
                [self tmsd_stopImageIndicator];
            }
#endif
            
            BOOL shouldCallCompletedBlock = finished || (options & TMSDWebImageAvoidAutoSetImage);
            BOOL shouldNotSetImage = ((image && (options & TMSDWebImageAvoidAutoSetImage)) ||
                                      (!image && !(options & TMSDWebImageDelayPlaceholder)));
            TMSDWebImageNoParamsBlock callCompletedBlockClosure = ^{
                if (!self) { return; }
                if (!shouldNotSetImage) {
                    [self tmsd_setNeedsLayout];
                }
                if (completedBlock && shouldCallCompletedBlock) {
                    completedBlock(image, data, error, cacheType, finished, url);
                }
            };
            
            // case 1a: we got an image, but the TMSDWebImageAvoidAutoSetImage flag is set
            // OR
            // case 1b: we got no image and the TMSDWebImageDelayPlaceholder is not set
            if (shouldNotSetImage) {
                dispatch_main_async_safe(callCompletedBlockClosure);
                return;
            }
            
            UIImage *targetImage = nil;
            NSData *targetData = nil;
            if (image) {
                // case 2a: we got an image and the TMSDWebImageAvoidAutoSetImage is not set
                targetImage = image;
                targetData = data;
            } else if (options & TMSDWebImageDelayPlaceholder) {
                // case 2b: we got no image and the TMSDWebImageDelayPlaceholder flag is set
                targetImage = placeholder;
                targetData = nil;
            }
            
#if TMSD_UIKIT || TMSD_MAC
            // check whether we should use the image transition
            TMSDWebImageTransition *transition = nil;
            BOOL shouldUseTransition = NO;
            if (options & TMSDWebImageForceTransition) {
                // Always
                shouldUseTransition = YES;
            } else if (cacheType == TMSDImageCacheTypeNone) {
                // From network
                shouldUseTransition = YES;
            } else {
                // From disk (and, user don't use sync query)
                if (cacheType == TMSDImageCacheTypeMemory) {
                    shouldUseTransition = NO;
                } else if (cacheType == TMSDImageCacheTypeDisk) {
                    if (options & TMSDWebImageQueryMemoryDataSync || options & TMSDWebImageQueryDiskDataSync) {
                        shouldUseTransition = NO;
                    } else {
                        shouldUseTransition = YES;
                    }
                } else {
                    // Not valid cache type, fallback
                    shouldUseTransition = NO;
                }
            }
            if (finished && shouldUseTransition) {
                transition = self.tmsd_imageTransition;
            }
#endif
            dispatch_main_async_safe(^{
#if TMSD_UIKIT || TMSD_MAC
                [self tmsd_setImage:targetImage imageData:targetData basedOnClassOrViaCustomSetImageBlock:setImageBlock transition:transition cacheType:cacheType imageURL:imageURL];
#else
                [self tmsd_setImage:targetImage imageData:targetData basedOnClassOrViaCustomSetImageBlock:setImageBlock cacheType:cacheType imageURL:imageURL];
#endif
                callCompletedBlockClosure();
            });
        }];
        [self tmsd_setImageLoadOperation:operation forKey:validOperationKey];
    } else {
#if TMSD_UIKIT || TMSD_MAC
        [self tmsd_stopImageIndicator];
#endif
        dispatch_main_async_safe(^{
            if (completedBlock) {
                NSError *error = [NSError errorWithDomain:TMSDWebImageErrorDomain code:TMSDWebImageErrorInvalidURL userInfo:@{NSLocalizedDescriptionKey : @"Image url is nil"}];
                completedBlock(nil, nil, error, TMSDImageCacheTypeNone, YES, url);
            }
        });
    }
    
    return operation;
}

- (void)tmsd_cancelCurrentImageLoad {
    [self tmsd_cancelImageLoadOperationWithKey:self.tmsd_latestOperationKey];
    self.tmsd_latestOperationKey = nil;
}

- (void)tmsd_setImage:(UIImage *)image imageData:(NSData *)imageData basedOnClassOrViaCustomSetImageBlock:(TMSDSetImageBlock)setImageBlock cacheType:(TMSDImageCacheType)cacheType imageURL:(NSURL *)imageURL {
#if TMSD_UIKIT || TMSD_MAC
    [self tmsd_setImage:image imageData:imageData basedOnClassOrViaCustomSetImageBlock:setImageBlock transition:nil cacheType:cacheType imageURL:imageURL];
#else
    // watchOS does not support view transition. Simplify the logic
    if (setImageBlock) {
        setImageBlock(image, imageData, cacheType, imageURL);
    } else if ([self isKindOfClass:[UIImageView class]]) {
        UIImageView *imageView = (UIImageView *)self;
        [imageView setImage:image];
    }
#endif
}

#if TMSD_UIKIT || TMSD_MAC
- (void)tmsd_setImage:(UIImage *)image imageData:(NSData *)imageData basedOnClassOrViaCustomSetImageBlock:(TMSDSetImageBlock)setImageBlock transition:(TMSDWebImageTransition *)transition cacheType:(TMSDImageCacheType)cacheType imageURL:(NSURL *)imageURL {
    UIView *view = self;
    TMSDSetImageBlock finalSetImageBlock;
    if (setImageBlock) {
        finalSetImageBlock = setImageBlock;
    } else if ([view isKindOfClass:[UIImageView class]]) {
        UIImageView *imageView = (UIImageView *)view;
        finalSetImageBlock = ^(UIImage *setImage, NSData *setImageData, TMSDImageCacheType setCacheType, NSURL *setImageURL) {
            imageView.image = setImage;
        };
    }
#if TMSD_UIKIT
    else if ([view isKindOfClass:[UIButton class]]) {
        UIButton *button = (UIButton *)view;
        finalSetImageBlock = ^(UIImage *setImage, NSData *setImageData, TMSDImageCacheType setCacheType, NSURL *setImageURL) {
            [button setImage:setImage forState:UIControlStateNormal];
        };
    }
#endif
#if TMSD_MAC
    else if ([view isKindOfClass:[NSButton class]]) {
        NSButton *button = (NSButton *)view;
        finalSetImageBlock = ^(UIImage *setImage, NSData *setImageData, TMSDImageCacheType setCacheType, NSURL *setImageURL) {
            button.image = setImage;
        };
    }
#endif
    
    if (transition) {
        NSString *originalOperationKey = view.tmsd_latestOperationKey;

#if TMSD_UIKIT
        [UIView transitionWithView:view duration:0 options:0 animations:^{
            if (!view.tmsd_latestOperationKey || ![originalOperationKey isEqualToString:view.tmsd_latestOperationKey]) {
                return;
            }
            // 0 duration to let UIKit render placeholder and prepares block
            if (transition.prepares) {
                transition.prepares(view, image, imageData, cacheType, imageURL);
            }
        } completion:^(BOOL tempFinished) {
            [UIView transitionWithView:view duration:transition.duration options:transition.animationOptions animations:^{
                if (!view.tmsd_latestOperationKey || ![originalOperationKey isEqualToString:view.tmsd_latestOperationKey]) {
                    return;
                }
                if (finalSetImageBlock && !transition.avoidAutoSetImage) {
                    finalSetImageBlock(image, imageData, cacheType, imageURL);
                }
                if (transition.animations) {
                    transition.animations(view, image);
                }
            } completion:^(BOOL finished) {
                if (!view.tmsd_latestOperationKey || ![originalOperationKey isEqualToString:view.tmsd_latestOperationKey]) {
                    return;
                }
                if (transition.completion) {
                    transition.completion(finished);
                }
            }];
        }];
#elif TMSD_MAC
        [NSAnimationContext runAnimationGroup:^(NSAnimationContext * _Nonnull prepareContext) {
            if (!view.tmsd_latestOperationKey || ![originalOperationKey isEqualToString:view.tmsd_latestOperationKey]) {
                return;
            }
            // 0 duration to let AppKit render placeholder and prepares block
            prepareContext.duration = 0;
            if (transition.prepares) {
                transition.prepares(view, image, imageData, cacheType, imageURL);
            }
        } completionHandler:^{
            [NSAnimationContext runAnimationGroup:^(NSAnimationContext * _Nonnull context) {
                if (!view.tmsd_latestOperationKey || ![originalOperationKey isEqualToString:view.tmsd_latestOperationKey]) {
                    return;
                }
                context.duration = transition.duration;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
                CAMediaTimingFunction *timingFunction = transition.timingFunction;
#pragma clang diagnostic pop
                if (!timingFunction) {
                    timingFunction = TMSDTimingFunctionFromAnimationOptions(transition.animationOptions);
                }
                context.timingFunction = timingFunction;
                context.allowsImplicitAnimation = TMSD_OPTIONS_CONTAINS(transition.animationOptions, TMSDWebImageAnimationOptionAllowsImplicitAnimation);
                if (finalSetImageBlock && !transition.avoidAutoSetImage) {
                    finalSetImageBlock(image, imageData, cacheType, imageURL);
                }
                CATransition *trans = TMSDTransitionFromAnimationOptions(transition.animationOptions);
                if (trans) {
                    [view.layer addAnimation:trans forKey:kCATransition];
                }
                if (transition.animations) {
                    transition.animations(view, image);
                }
            } completionHandler:^{
                if (!view.tmsd_latestOperationKey || ![originalOperationKey isEqualToString:view.tmsd_latestOperationKey]) {
                    return;
                }
                if (transition.completion) {
                    transition.completion(YES);
                }
            }];
        }];
#endif
    } else {
        if (finalSetImageBlock) {
            finalSetImageBlock(image, imageData, cacheType, imageURL);
        }
    }
}
#endif

- (void)tmsd_setNeedsLayout {
#if TMSD_UIKIT
    [self setNeedsLayout];
#elif TMSD_MAC
    [self setNeedsLayout:YES];
#elif TMSD_WATCH
    // Do nothing because WatchKit automatically layout the view after property change
#endif
}

#if TMSD_UIKIT || TMSD_MAC

#pragma mark - Image Transition
- (TMSDWebImageTransition *)tmsd_imageTransition {
    return objc_getAssociatedObject(self, @selector(tmsd_imageTransition));
}

- (void)setTmsd_imageTransition:(TMSDWebImageTransition *)tmsd_imageTransition {
    objc_setAssociatedObject(self, @selector(tmsd_imageTransition), tmsd_imageTransition, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

#pragma mark - Indicator
- (id<TMSDWebImageIndicator>)tmsd_imageIndicator {
    return objc_getAssociatedObject(self, @selector(tmsd_imageIndicator));
}

- (void)setTmsd_imageIndicator:(id<TMSDWebImageIndicator>)tmsd_imageIndicator {
    // Remove the old indicator view
    id<TMSDWebImageIndicator> previousIndicator = self.tmsd_imageIndicator;
    [previousIndicator.indicatorView removeFromSuperview];
    
    objc_setAssociatedObject(self, @selector(tmsd_imageIndicator), tmsd_imageIndicator, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    // Add the new indicator view
    UIView *view = tmsd_imageIndicator.indicatorView;
    if (CGRectEqualToRect(view.frame, CGRectZero)) {
        view.frame = self.bounds;
    }
    // Center the indicator view
#if TMSD_MAC
    [view setFrameOrigin:CGPointMake(round((NSWidth(self.bounds) - NSWidth(view.frame)) / 2), round((NSHeight(self.bounds) - NSHeight(view.frame)) / 2))];
#else
    view.center = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
#endif
    view.hidden = NO;
    [self addSubview:view];
}

- (void)tmsd_startImageIndicator {
    id<TMSDWebImageIndicator> imageIndicator = self.tmsd_imageIndicator;
    if (!imageIndicator) {
        return;
    }
    dispatch_main_async_safe(^{
        [imageIndicator startAnimatingIndicator];
    });
}

- (void)tmsd_stopImageIndicator {
    id<TMSDWebImageIndicator> imageIndicator = self.tmsd_imageIndicator;
    if (!imageIndicator) {
        return;
    }
    dispatch_main_async_safe(^{
        [imageIndicator stopAnimatingIndicator];
    });
}

#endif

@end
