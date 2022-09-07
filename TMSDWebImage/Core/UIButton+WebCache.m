/*
 * This file is part of the TMSDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import <TMSDWebImage/UIButton+WebCache.h>

#if TMSD_UIKIT

#import "objc/runtime.h"
#import <TMSDWebImage/UIView+WebCacheOperation.h>
#import <TMSDWebImage/UIView+WebCache.h>
#import <TMSDWebImage/TMSDInternalMacros.h>

static char imageURLStorageKey;

typedef NSMutableDictionary<NSString *, NSURL *> TMSDStateImageURLDictionary;

static inline NSString * imageURLKeyForState(UIControlState state) {
    return [NSString stringWithFormat:@"image_%lu", (unsigned long)state];
}

static inline NSString * backgroundImageURLKeyForState(UIControlState state) {
    return [NSString stringWithFormat:@"backgroundImage_%lu", (unsigned long)state];
}

static inline NSString * imageOperationKeyForState(UIControlState state) {
    return [NSString stringWithFormat:@"UIButtonImageOperation%lu", (unsigned long)state];
}

static inline NSString * backgroundImageOperationKeyForState(UIControlState state) {
    return [NSString stringWithFormat:@"UIButtonBackgroundImageOperation%lu", (unsigned long)state];
}

@implementation UIButton (TMSDWebCache)

#pragma mark - Image

- (nullable NSURL *)tmsd_currentImageURL {
    NSURL *url = self.tmsd_imageURLStorage[imageURLKeyForState(self.state)];

    if (!url) {
        url = self.tmsd_imageURLStorage[imageURLKeyForState(UIControlStateNormal)];
    }

    return url;
}

- (nullable NSURL *)tmsd_imageURLForState:(UIControlState)state {
    return self.tmsd_imageURLStorage[imageURLKeyForState(state)];
}

- (void)tmsd_setImageWithURL:(nullable NSURL *)url forState:(UIControlState)state {
    [self tmsd_setImageWithURL:url forState:state placeholderImage:nil options:0 completed:nil];
}

- (void)tmsd_setImageWithURL:(nullable NSURL *)url forState:(UIControlState)state placeholderImage:(nullable UIImage *)placeholder {
    [self tmsd_setImageWithURL:url forState:state placeholderImage:placeholder options:0 completed:nil];
}

- (void)tmsd_setImageWithURL:(nullable NSURL *)url forState:(UIControlState)state placeholderImage:(nullable UIImage *)placeholder options:(TMSDWebImageOptions)options {
    [self tmsd_setImageWithURL:url forState:state placeholderImage:placeholder options:options progress:nil completed:nil];
}

- (void)tmsd_setImageWithURL:(nullable NSURL *)url forState:(UIControlState)state placeholderImage:(nullable UIImage *)placeholder options:(TMSDWebImageOptions)options context:(nullable TMSDWebImageContext *)context {
    [self tmsd_setImageWithURL:url forState:state placeholderImage:placeholder options:options context:context progress:nil completed:nil];
}

- (void)tmsd_setImageWithURL:(nullable NSURL *)url forState:(UIControlState)state completed:(nullable TMSDExternalCompletionBlock)completedBlock {
    [self tmsd_setImageWithURL:url forState:state placeholderImage:nil options:0 completed:completedBlock];
}

- (void)tmsd_setImageWithURL:(nullable NSURL *)url forState:(UIControlState)state placeholderImage:(nullable UIImage *)placeholder completed:(nullable TMSDExternalCompletionBlock)completedBlock {
    [self tmsd_setImageWithURL:url forState:state placeholderImage:placeholder options:0 completed:completedBlock];
}

- (void)tmsd_setImageWithURL:(nullable NSURL *)url forState:(UIControlState)state placeholderImage:(nullable UIImage *)placeholder options:(TMSDWebImageOptions)options completed:(nullable TMSDExternalCompletionBlock)completedBlock {
    [self tmsd_setImageWithURL:url forState:state placeholderImage:placeholder options:options progress:nil completed:completedBlock];
}

- (void)tmsd_setImageWithURL:(nullable NSURL *)url forState:(UIControlState)state placeholderImage:(nullable UIImage *)placeholder options:(TMSDWebImageOptions)options progress:(nullable TMSDImageLoaderProgressBlock)progressBlock completed:(nullable TMSDExternalCompletionBlock)completedBlock {
    [self tmsd_setImageWithURL:url forState:state placeholderImage:placeholder options:options context:nil progress:progressBlock completed:completedBlock];
}

- (void)tmsd_setImageWithURL:(nullable NSURL *)url
                  forState:(UIControlState)state
          placeholderImage:(nullable UIImage *)placeholder
                   options:(TMSDWebImageOptions)options
                   context:(nullable TMSDWebImageContext *)context
                  progress:(nullable TMSDImageLoaderProgressBlock)progressBlock
                 completed:(nullable TMSDExternalCompletionBlock)completedBlock {
    if (!url) {
        [self.tmsd_imageURLStorage removeObjectForKey:imageURLKeyForState(state)];
    } else {
        self.tmsd_imageURLStorage[imageURLKeyForState(state)] = url;
    }
    
    TMSDWebImageMutableContext *mutableContext;
    if (context) {
        mutableContext = [context mutableCopy];
    } else {
        mutableContext = [NSMutableDictionary dictionary];
    }
    mutableContext[TMSDWebImageContextSetImageOperationKey] = imageOperationKeyForState(state);
    @weakify(self);
    [self tmsd_internalSetImageWithURL:url
                    placeholderImage:placeholder
                             options:options
                             context:mutableContext
                       setImageBlock:^(UIImage * _Nullable image, NSData * _Nullable imageData, TMSDImageCacheType cacheType, NSURL * _Nullable imageURL) {
                           @strongify(self);
                           [self setImage:image forState:state];
                       }
                            progress:progressBlock
                           completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, TMSDImageCacheType cacheType, BOOL finished, NSURL * _Nullable imageURL) {
                               if (completedBlock) {
                                   completedBlock(image, error, cacheType, imageURL);
                               }
                           }];
}

#pragma mark - Background Image

- (nullable NSURL *)tmsd_currentBackgroundImageURL {
    NSURL *url = self.tmsd_imageURLStorage[backgroundImageURLKeyForState(self.state)];
    
    if (!url) {
        url = self.tmsd_imageURLStorage[backgroundImageURLKeyForState(UIControlStateNormal)];
    }
    
    return url;
}

- (nullable NSURL *)tmsd_backgroundImageURLForState:(UIControlState)state {
    return self.tmsd_imageURLStorage[backgroundImageURLKeyForState(state)];
}

- (void)tmsd_setBackgroundImageWithURL:(nullable NSURL *)url forState:(UIControlState)state {
    [self tmsd_setBackgroundImageWithURL:url forState:state placeholderImage:nil options:0 completed:nil];
}

- (void)tmsd_setBackgroundImageWithURL:(nullable NSURL *)url forState:(UIControlState)state placeholderImage:(nullable UIImage *)placeholder {
    [self tmsd_setBackgroundImageWithURL:url forState:state placeholderImage:placeholder options:0 completed:nil];
}

- (void)tmsd_setBackgroundImageWithURL:(nullable NSURL *)url forState:(UIControlState)state placeholderImage:(nullable UIImage *)placeholder options:(TMSDWebImageOptions)options {
    [self tmsd_setBackgroundImageWithURL:url forState:state placeholderImage:placeholder options:options progress:nil completed:nil];
}

- (void)tmsd_setBackgroundImageWithURL:(nullable NSURL *)url forState:(UIControlState)state placeholderImage:(nullable UIImage *)placeholder options:(TMSDWebImageOptions)options context:(nullable TMSDWebImageContext *)context {
    [self tmsd_setBackgroundImageWithURL:url forState:state placeholderImage:placeholder options:options context:context progress:nil completed:nil];
}

- (void)tmsd_setBackgroundImageWithURL:(nullable NSURL *)url forState:(UIControlState)state completed:(nullable TMSDExternalCompletionBlock)completedBlock {
    [self tmsd_setBackgroundImageWithURL:url forState:state placeholderImage:nil options:0 completed:completedBlock];
}

- (void)tmsd_setBackgroundImageWithURL:(nullable NSURL *)url forState:(UIControlState)state placeholderImage:(nullable UIImage *)placeholder completed:(nullable TMSDExternalCompletionBlock)completedBlock {
    [self tmsd_setBackgroundImageWithURL:url forState:state placeholderImage:placeholder options:0 completed:completedBlock];
}

- (void)tmsd_setBackgroundImageWithURL:(nullable NSURL *)url forState:(UIControlState)state placeholderImage:(nullable UIImage *)placeholder options:(TMSDWebImageOptions)options completed:(nullable TMSDExternalCompletionBlock)completedBlock {
    [self tmsd_setBackgroundImageWithURL:url forState:state placeholderImage:placeholder options:options progress:nil completed:completedBlock];
}

- (void)tmsd_setBackgroundImageWithURL:(nullable NSURL *)url forState:(UIControlState)state placeholderImage:(nullable UIImage *)placeholder options:(TMSDWebImageOptions)options progress:(nullable TMSDImageLoaderProgressBlock)progressBlock completed:(nullable TMSDExternalCompletionBlock)completedBlock {
    [self tmsd_setBackgroundImageWithURL:url forState:state placeholderImage:placeholder options:options context:nil progress:progressBlock completed:completedBlock];
}

- (void)tmsd_setBackgroundImageWithURL:(nullable NSURL *)url
                            forState:(UIControlState)state
                    placeholderImage:(nullable UIImage *)placeholder
                             options:(TMSDWebImageOptions)options
                             context:(nullable TMSDWebImageContext *)context
                            progress:(nullable TMSDImageLoaderProgressBlock)progressBlock
                           completed:(nullable TMSDExternalCompletionBlock)completedBlock {
    if (!url) {
        [self.tmsd_imageURLStorage removeObjectForKey:backgroundImageURLKeyForState(state)];
    } else {
        self.tmsd_imageURLStorage[backgroundImageURLKeyForState(state)] = url;
    }
    
    TMSDWebImageMutableContext *mutableContext;
    if (context) {
        mutableContext = [context mutableCopy];
    } else {
        mutableContext = [NSMutableDictionary dictionary];
    }
    mutableContext[TMSDWebImageContextSetImageOperationKey] = backgroundImageOperationKeyForState(state);
    @weakify(self);
    [self tmsd_internalSetImageWithURL:url
                    placeholderImage:placeholder
                             options:options
                             context:mutableContext
                       setImageBlock:^(UIImage * _Nullable image, NSData * _Nullable imageData, TMSDImageCacheType cacheType, NSURL * _Nullable imageURL) {
                           @strongify(self);
                           [self setBackgroundImage:image forState:state];
                       }
                            progress:progressBlock
                           completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, TMSDImageCacheType cacheType, BOOL finished, NSURL * _Nullable imageURL) {
                               if (completedBlock) {
                                   completedBlock(image, error, cacheType, imageURL);
                               }
                           }];
}

#pragma mark - Cancel

- (void)tmsd_cancelImageLoadForState:(UIControlState)state {
    [self tmsd_cancelImageLoadOperationWithKey:imageOperationKeyForState(state)];
}

- (void)tmsd_cancelBackgroundImageLoadForState:(UIControlState)state {
    [self tmsd_cancelImageLoadOperationWithKey:backgroundImageOperationKeyForState(state)];
}

#pragma mark - Private

- (TMSDStateImageURLDictionary *)tmsd_imageURLStorage {
    TMSDStateImageURLDictionary *storage = objc_getAssociatedObject(self, &imageURLStorageKey);
    if (!storage) {
        storage = [NSMutableDictionary dictionary];
        objc_setAssociatedObject(self, &imageURLStorageKey, storage, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }

    return storage;
}

@end

#endif
