/*
 * This file is part of the TMSDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import <TMSDWebImage/MKAnnotationView+WebCache.h>

#if TMSD_UIKIT || TMSD_MAC

@implementation MKAnnotationView (TMSDWebCache)

- (void)tmsd_setImageWithURL:(nullable NSURL *)url {
    [self tmsd_setImageWithURL:url placeholderImage:nil options:0 completed:nil];
}

- (void)tmsd_setImageWithURL:(nullable NSURL *)url placeholderImage:(nullable UIImage *)placeholder {
    [self tmsd_setImageWithURL:url placeholderImage:placeholder options:0 completed:nil];
}

- (void)tmsd_setImageWithURL:(nullable NSURL *)url placeholderImage:(nullable UIImage *)placeholder options:(TMSDWebImageOptions)options {
    [self tmsd_setImageWithURL:url placeholderImage:placeholder options:options progress:nil completed:nil];
}

- (void)tmsd_setImageWithURL:(nullable NSURL *)url placeholderImage:(nullable UIImage *)placeholder options:(TMSDWebImageOptions)options context:(nullable TMSDWebImageContext *)context {
    [self tmsd_setImageWithURL:url placeholderImage:placeholder options:options context:context progress:nil completed:nil];
}

- (void)tmsd_setImageWithURL:(nullable NSURL *)url completed:(nullable TMSDExternalCompletionBlock)completedBlock {
    [self tmsd_setImageWithURL:url placeholderImage:nil options:0 completed:completedBlock];
}

- (void)tmsd_setImageWithURL:(nullable NSURL *)url placeholderImage:(nullable UIImage *)placeholder completed:(nullable TMSDExternalCompletionBlock)completedBlock {
    [self tmsd_setImageWithURL:url placeholderImage:placeholder options:0 completed:completedBlock];
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
    __weak typeof(self) wself = self;
    [self tmsd_internalSetImageWithURL:url
                    placeholderImage:placeholder
                             options:options
                             context:context
                       setImageBlock:^(UIImage * _Nullable image, NSData * _Nullable imageData, TMSDImageCacheType cacheType, NSURL * _Nullable imageURL) {
                           wself.image = image;
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
