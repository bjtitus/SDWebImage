/*
 * This file is part of the TMSDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import <TMSDWebImage/TMSDImageLoadersManager.h>
#import <TMSDWebImage/TMSDWebImageDownloader.h>
#import <TMSDWebImage/TMSDInternalMacros.h>

@interface TMSDImageLoadersManager ()

@property (nonatomic, strong, nonnull) NSMutableArray<id<TMSDImageLoader>> *imageLoaders;

@end

@implementation TMSDImageLoadersManager {
    TMSD_LOCK_DECLARE(_loadersLock);
}

+ (TMSDImageLoadersManager *)sharedManager {
    static dispatch_once_t onceToken;
    static TMSDImageLoadersManager *manager;
    dispatch_once(&onceToken, ^{
        manager = [[TMSDImageLoadersManager alloc] init];
    });
    return manager;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        // initialize with default image loaders
        _imageLoaders = [NSMutableArray arrayWithObject:[TMSDWebImageDownloader sharedDownloader]];
        TMSD_LOCK_INIT(_loadersLock);
    }
    return self;
}

- (NSArray<id<TMSDImageLoader>> *)loaders {
    TMSD_LOCK(_loadersLock);
    NSArray<id<TMSDImageLoader>>* loaders = [_imageLoaders copy];
    TMSD_UNLOCK(_loadersLock);
    return loaders;
}

- (void)setLoaders:(NSArray<id<TMSDImageLoader>> *)loaders {
    TMSD_LOCK(_loadersLock);
    [_imageLoaders removeAllObjects];
    if (loaders.count) {
        [_imageLoaders addObjectsFromArray:loaders];
    }
    TMSD_UNLOCK(_loadersLock);
}

#pragma mark - Loader Property

- (void)addLoader:(id<TMSDImageLoader>)loader {
    if (![loader conformsToProtocol:@protocol(TMSDImageLoader)]) {
        return;
    }
    TMSD_LOCK(_loadersLock);
    [_imageLoaders addObject:loader];
    TMSD_UNLOCK(_loadersLock);
}

- (void)removeLoader:(id<TMSDImageLoader>)loader {
    if (![loader conformsToProtocol:@protocol(TMSDImageLoader)]) {
        return;
    }
    TMSD_LOCK(_loadersLock);
    [_imageLoaders removeObject:loader];
    TMSD_UNLOCK(_loadersLock);
}

#pragma mark - TMSDImageLoader

- (BOOL)canRequestImageForURL:(nullable NSURL *)url {
    return [self canRequestImageForURL:url options:0 context:nil];
}

- (BOOL)canRequestImageForURL:(NSURL *)url options:(TMSDWebImageOptions)options context:(TMSDWebImageContext *)context {
    NSArray<id<TMSDImageLoader>> *loaders = self.loaders;
    for (id<TMSDImageLoader> loader in loaders.reverseObjectEnumerator) {
        if ([loader respondsToSelector:@selector(canRequestImageForURL:options:context:)]) {
            if ([loader canRequestImageForURL:url options:options context:context]) {
                return YES;
            }
        } else {
            if ([loader canRequestImageForURL:url]) {
                return YES;
            }
        }
    }
    return NO;
}

- (id<TMSDWebImageOperation>)requestImageWithURL:(NSURL *)url options:(TMSDWebImageOptions)options context:(TMSDWebImageContext *)context progress:(TMSDImageLoaderProgressBlock)progressBlock completed:(TMSDImageLoaderCompletedBlock)completedBlock {
    if (!url) {
        return nil;
    }
    NSArray<id<TMSDImageLoader>> *loaders = self.loaders;
    for (id<TMSDImageLoader> loader in loaders.reverseObjectEnumerator) {
        if ([loader canRequestImageForURL:url]) {
            return [loader requestImageWithURL:url options:options context:context progress:progressBlock completed:completedBlock];
        }
    }
    return nil;
}

- (BOOL)shouldBlockFailedURLWithURL:(NSURL *)url error:(NSError *)error {
    NSArray<id<TMSDImageLoader>> *loaders = self.loaders;
    for (id<TMSDImageLoader> loader in loaders.reverseObjectEnumerator) {
        if ([loader canRequestImageForURL:url]) {
            return [loader shouldBlockFailedURLWithURL:url error:error];
        }
    }
    return NO;
}

@end
