/*
 * This file is part of the TMSDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import <TMSDWebImage/UIImageView+HighlightedWebCache.h>

#if TMSD_UIKIT

#import <TMSDWebImage/UIView+WebCacheOperation.h>
#import <TMSDWebImage/UIView+WebCache.h>
#import <TMSDWebImage/TMSDInternalMacros.h>

static NSString * const TMSDHighlightedImageOperationKey = @"UIImageViewImageOperationHighlighted";

@implementation UIImageView (TMSDHighlightedWebCache)

- (void)tmsd_setHighlightedImageWithURL:(nullable NSURL *)url {
    [self tmsd_setHighlightedImageWithURL:url options:0 progress:nil completed:nil];
}

- (void)tmsd_setHighlightedImageWithURL:(nullable NSURL *)url options:(TMSDWebImageOptions)options {
    [self tmsd_setHighlightedImageWithURL:url options:options progress:nil completed:nil];
}

- (void)tmsd_setHighlightedImageWithURL:(nullable NSURL *)url options:(TMSDWebImageOptions)options context:(nullable TMSDWebImageContext *)context {
    [self tmsd_setHighlightedImageWithURL:url options:options context:context progress:nil completed:nil];
}

- (void)tmsd_setHighlightedImageWithURL:(nullable NSURL *)url completed:(nullable TMSDExternalCompletionBlock)completedBlock {
    [self tmsd_setHighlightedImageWithURL:url options:0 progress:nil completed:completedBlock];
}

- (void)tmsd_setHighlightedImageWithURL:(nullable NSURL *)url options:(TMSDWebImageOptions)options completed:(nullable TMSDExternalCompletionBlock)completedBlock {
    [self tmsd_setHighlightedImageWithURL:url options:options progress:nil completed:completedBlock];
}

- (void)tmsd_setHighlightedImageWithURL:(NSURL *)url options:(TMSDWebImageOptions)options progress:(nullable TMSDImageLoaderProgressBlock)progressBlock completed:(nullable TMSDExternalCompletionBlock)completedBlock {
    [self tmsd_setHighlightedImageWithURL:url options:options context:nil progress:progressBlock completed:completedBlock];
}

- (void)tmsd_setHighlightedImageWithURL:(nullable NSURL *)url
                              options:(TMSDWebImageOptions)options
                              context:(nullable TMSDWebImageContext *)context
                             progress:(nullable TMSDImageLoaderProgressBlock)progressBlock
                            completed:(nullable TMSDExternalCompletionBlock)completedBlock {
    @weakify(self);
    TMSDWebImageMutableContext *mutableContext;
    if (context) {
        mutableContext = [context mutableCopy];
    } else {
        mutableContext = [NSMutableDictionary dictionary];
    }
    mutableContext[TMSDWebImageContextSetImageOperationKey] = TMSDHighlightedImageOperationKey;
    [self tmsd_internalSetImageWithURL:url
                    placeholderImage:nil
                             options:options
                             context:mutableContext
                       setImageBlock:^(UIImage * _Nullable image, NSData * _Nullable imageData, TMSDImageCacheType cacheType, NSURL * _Nullable imageURL) {
                           @strongify(self);
                           self.highlightedImage = image;
                       }
                            progress:progressBlock
                           completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, TMSDImageCacheType cacheType, BOOL finished, NSURL * _Nullable imageURL) {
                               if (completedBlock) {
                                   completedBlock(image, error, cacheType, imageURL);
                               }
                           }];
}

@end

#endif
