/*
 * This file is part of the TMSDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import <TMSDWebImage/NSButton+WebCache.h>

#if TMSD_MAC

#import "objc/runtime.h"
#import <TMSDWebImage/UIView+WebCacheOperation.h>
#import <TMSDWebImage/UIView+WebCache.h>
#import <TMSDWebImage/TMSDInternalMacros.h>

static NSString * const TMSDAlternateImageOperationKey = @"NSButtonAlternateImageOperation";

@implementation NSButton (TMSDWebCache)

#pragma mark - Image

- (void)tmsd_setImageWithURL:(nullable NSURL *)url {
    [self tmsd_setImageWithURL:url placeholderImage:nil options:0 progress:nil completed:nil];
}

- (void)tmsd_setImageWithURL:(nullable NSURL *)url placeholderImage:(nullable UIImage *)placeholder {
    [self tmsd_setImageWithURL:url placeholderImage:placeholder options:0 progress:nil completed:nil];
}

- (void)tmsd_setImageWithURL:(nullable NSURL *)url placeholderImage:(nullable UIImage *)placeholder options:(TMSDWebImageOptions)options {
    [self tmsd_setImageWithURL:url placeholderImage:placeholder options:options progress:nil completed:nil];
}

- (void)tmsd_setImageWithURL:(nullable NSURL *)url placeholderImage:(nullable UIImage *)placeholder options:(TMSDWebImageOptions)options context:(nullable TMSDWebImageContext *)context {
    [self tmsd_setImageWithURL:url placeholderImage:placeholder options:options context:context progress:nil completed:nil];
}

- (void)tmsd_setImageWithURL:(nullable NSURL *)url completed:(nullable TMSDExternalCompletionBlock)completedBlock {
    [self tmsd_setImageWithURL:url placeholderImage:nil options:0 progress:nil completed:completedBlock];
}

- (void)tmsd_setImageWithURL:(nullable NSURL *)url placeholderImage:(nullable UIImage *)placeholder completed:(nullable TMSDExternalCompletionBlock)completedBlock {
    [self tmsd_setImageWithURL:url placeholderImage:placeholder options:0 progress:nil completed:completedBlock];
}

- (void)tmsd_setImageWithURL:(nullable NSURL *)url placeholderImage:(nullable UIImage *)placeholder options:(TMSDWebImageOptions)options completed:(nullable TMSDExternalCompletionBlock)completedBlock {
    [self tmsd_setImageWithURL:url placeholderImage:placeholder options:options progress:nil completed:completedBlock];
}

- (void)tmsd_setImageWithURL:(nullable NSURL *)url placeholderImage:(nullable UIImage *)placeholder options:(TMSDWebImageOptions)options progress:(nullable TMSDImageLoaderProgressBlock)progressBlock completed:(nullable TMSDExternalCompletionBlock)completedBlock {
    [self tmsd_setImageWithURL:url placeholderImage:placeholder options:options context:nil progress:progressBlock completed:completedBlock];
}

- (void)tmsd_setImageWithURL:(nullable NSURL *)url
          placeholderImage:(nullable UIImage *)placeholder
                   options:(TMSDWebImageOptions)options
                   context:(nullable TMSDWebImageContext *)context
                  progress:(nullable TMSDImageLoaderProgressBlock)progressBlock
                 completed:(nullable TMSDExternalCompletionBlock)completedBlock {
    self.tmsd_currentImageURL = url;
    [self tmsd_internalSetImageWithURL:url
                    placeholderImage:placeholder
                             options:options
                             context:context
                       setImageBlock:nil
                            progress:progressBlock
                           completed:^(NSImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, TMSDImageCacheType cacheType, BOOL finished, NSURL * _Nullable imageURL) {
                               if (completedBlock) {
                                   completedBlock(image, error, cacheType, imageURL);
                               }
                           }];
}

#pragma mark - Alternate Image

- (void)tmsd_setAlternateImageWithURL:(nullable NSURL *)url {
    [self tmsd_setAlternateImageWithURL:url placeholderImage:nil options:0 progress:nil completed:nil];
}

- (void)tmsd_setAlternateImageWithURL:(nullable NSURL *)url placeholderImage:(nullable UIImage *)placeholder {
    [self tmsd_setAlternateImageWithURL:url placeholderImage:placeholder options:0 progress:nil completed:nil];
}

- (void)tmsd_setAlternateImageWithURL:(nullable NSURL *)url placeholderImage:(nullable UIImage *)placeholder options:(TMSDWebImageOptions)options {
    [self tmsd_setAlternateImageWithURL:url placeholderImage:placeholder options:options progress:nil completed:nil];
}

- (void)tmsd_setAlternateImageWithURL:(nullable NSURL *)url placeholderImage:(nullable UIImage *)placeholder options:(TMSDWebImageOptions)options context:(nullable TMSDWebImageContext *)context {
    [self tmsd_setAlternateImageWithURL:url placeholderImage:placeholder options:options context:context progress:nil completed:nil];
}

- (void)tmsd_setAlternateImageWithURL:(nullable NSURL *)url completed:(nullable TMSDExternalCompletionBlock)completedBlock {
    [self tmsd_setAlternateImageWithURL:url placeholderImage:nil options:0 progress:nil completed:completedBlock];
}

- (void)tmsd_setAlternateImageWithURL:(nullable NSURL *)url placeholderImage:(nullable UIImage *)placeholder completed:(nullable TMSDExternalCompletionBlock)completedBlock {
    [self tmsd_setAlternateImageWithURL:url placeholderImage:placeholder options:0 progress:nil completed:completedBlock];
}

- (void)tmsd_setAlternateImageWithURL:(nullable NSURL *)url placeholderImage:(nullable UIImage *)placeholder options:(TMSDWebImageOptions)options completed:(nullable TMSDExternalCompletionBlock)completedBlock {
    [self tmsd_setAlternateImageWithURL:url placeholderImage:placeholder options:options progress:nil completed:completedBlock];
}

- (void)tmsd_setAlternateImageWithURL:(nullable NSURL *)url placeholderImage:(nullable UIImage *)placeholder options:(TMSDWebImageOptions)options progress:(nullable TMSDImageLoaderProgressBlock)progressBlock completed:(nullable TMSDExternalCompletionBlock)completedBlock {
    [self tmsd_setAlternateImageWithURL:url placeholderImage:placeholder options:options context:nil progress:progressBlock completed:completedBlock];
}

- (void)tmsd_setAlternateImageWithURL:(nullable NSURL *)url
                   placeholderImage:(nullable UIImage *)placeholder
                            options:(TMSDWebImageOptions)options
                            context:(nullable TMSDWebImageContext *)context
                           progress:(nullable TMSDImageLoaderProgressBlock)progressBlock
                          completed:(nullable TMSDExternalCompletionBlock)completedBlock {
    self.tmsd_currentAlternateImageURL = url;
    
    TMSDWebImageMutableContext *mutableContext;
    if (context) {
        mutableContext = [context mutableCopy];
    } else {
        mutableContext = [NSMutableDictionary dictionary];
    }
    mutableContext[TMSDWebImageContextSetImageOperationKey] = TMSDAlternateImageOperationKey;
    @weakify(self);
    [self tmsd_internalSetImageWithURL:url
                    placeholderImage:placeholder
                             options:options
                             context:mutableContext
                       setImageBlock:^(NSImage * _Nullable image, NSData * _Nullable imageData, TMSDImageCacheType cacheType, NSURL * _Nullable imageURL) {
                           @strongify(self);
                           self.alternateImage = image;
                       }
                            progress:progressBlock
                           completed:^(NSImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, TMSDImageCacheType cacheType, BOOL finished, NSURL * _Nullable imageURL) {
                               if (completedBlock) {
                                   completedBlock(image, error, cacheType, imageURL);
                               }
                           }];
}

#pragma mark - Cancel

- (void)tmsd_cancelCurrentImageLoad {
    [self tmsd_cancelImageLoadOperationWithKey:NSStringFromClass([self class])];
}

- (void)tmsd_cancelCurrentAlternateImageLoad {
    [self tmsd_cancelImageLoadOperationWithKey:TMSDAlternateImageOperationKey];
}

#pragma mark - Private

- (NSURL *)tmsd_currentImageURL {
    return objc_getAssociatedObject(self, @selector(tmsd_currentImageURL));
}

- (void)setTmsd_currentImageURL:(NSURL *)tmsd_currentImageURL {
    objc_setAssociatedObject(self, @selector(tmsd_currentImageURL), tmsd_currentImageURL, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSURL *)tmsd_currentAlternateImageURL {
    return objc_getAssociatedObject(self, @selector(tmsd_currentAlternateImageURL));
}

- (void)setTmsd_currentAlternateImageURL:(NSURL *)tmsd_currentAlternateImageURL {
    objc_setAssociatedObject(self, @selector(tmsd_currentAlternateImageURL), tmsd_currentAlternateImageURL, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end

#endif
