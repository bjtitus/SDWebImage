/*
 * This file is part of the TMSDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import <TMSDWebImage/TMSDImageCachesManager.h>
#import <TMSDWebImage/TMSDImageCachesManagerOperation.h>
#import <TMSDWebImage/TMSDImageCache.h>
#import <TMSDWebImage/TMSDInternalMacros.h>

@interface TMSDImageCachesManager ()

@property (nonatomic, strong, nonnull) NSMutableArray<id<TMSDImageCache>> *imageCaches;

@end

@implementation TMSDImageCachesManager {
    TMSD_LOCK_DECLARE(_cachesLock);
}

+ (TMSDImageCachesManager *)sharedManager {
    static dispatch_once_t onceToken;
    static TMSDImageCachesManager *manager;
    dispatch_once(&onceToken, ^{
        manager = [[TMSDImageCachesManager alloc] init];
    });
    return manager;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.queryOperationPolicy = TMSDImageCachesManagerOperationPolicySerial;
        self.storeOperationPolicy = TMSDImageCachesManagerOperationPolicyHighestOnly;
        self.removeOperationPolicy = TMSDImageCachesManagerOperationPolicyConcurrent;
        self.containsOperationPolicy = TMSDImageCachesManagerOperationPolicySerial;
        self.clearOperationPolicy = TMSDImageCachesManagerOperationPolicyConcurrent;
        // initialize with default image caches
        _imageCaches = [NSMutableArray arrayWithObject:[TMSDImageCache sharedImageCache]];
        TMSD_LOCK_INIT(_cachesLock);
    }
    return self;
}

- (NSArray<id<TMSDImageCache>> *)caches {
    TMSD_LOCK(_cachesLock);
    NSArray<id<TMSDImageCache>> *caches = [_imageCaches copy];
    TMSD_UNLOCK(_cachesLock);
    return caches;
}

- (void)setCaches:(NSArray<id<TMSDImageCache>> *)caches {
    TMSD_LOCK(_cachesLock);
    [_imageCaches removeAllObjects];
    if (caches.count) {
        [_imageCaches addObjectsFromArray:caches];
    }
    TMSD_UNLOCK(_cachesLock);
}

#pragma mark - Cache IO operations

- (void)addCache:(id<TMSDImageCache>)cache {
    if (![cache conformsToProtocol:@protocol(TMSDImageCache)]) {
        return;
    }
    TMSD_LOCK(_cachesLock);
    [_imageCaches addObject:cache];
    TMSD_UNLOCK(_cachesLock);
}

- (void)removeCache:(id<TMSDImageCache>)cache {
    if (![cache conformsToProtocol:@protocol(TMSDImageCache)]) {
        return;
    }
    TMSD_LOCK(_cachesLock);
    [_imageCaches removeObject:cache];
    TMSD_UNLOCK(_cachesLock);
}

#pragma mark - TMSDImageCache

- (id<TMSDWebImageOperation>)queryImageForKey:(NSString *)key options:(TMSDWebImageOptions)options context:(TMSDWebImageContext *)context completion:(TMSDImageCacheQueryCompletionBlock)completionBlock {
    return [self queryImageForKey:key options:options context:context cacheType:TMSDImageCacheTypeAll completion:completionBlock];
}

- (id<TMSDWebImageOperation>)queryImageForKey:(NSString *)key options:(TMSDWebImageOptions)options context:(TMSDWebImageContext *)context cacheType:(TMSDImageCacheType)cacheType completion:(TMSDImageCacheQueryCompletionBlock)completionBlock {
    if (!key) {
        return nil;
    }
    NSArray<id<TMSDImageCache>> *caches = self.caches;
    NSUInteger count = caches.count;
    if (count == 0) {
        return nil;
    } else if (count == 1) {
        return [caches.firstObject queryImageForKey:key options:options context:context cacheType:cacheType completion:completionBlock];
    }
    switch (self.queryOperationPolicy) {
        case TMSDImageCachesManagerOperationPolicyHighestOnly: {
            id<TMSDImageCache> cache = caches.lastObject;
            return [cache queryImageForKey:key options:options context:context cacheType:cacheType completion:completionBlock];
        }
            break;
        case TMSDImageCachesManagerOperationPolicyLowestOnly: {
            id<TMSDImageCache> cache = caches.firstObject;
            return [cache queryImageForKey:key options:options context:context cacheType:cacheType completion:completionBlock];
        }
            break;
        case TMSDImageCachesManagerOperationPolicyConcurrent: {
            TMSDImageCachesManagerOperation *operation = [TMSDImageCachesManagerOperation new];
            [operation beginWithTotalCount:caches.count];
            [self concurrentQueryImageForKey:key options:options context:context cacheType:cacheType completion:completionBlock enumerator:caches.reverseObjectEnumerator operation:operation];
            return operation;
        }
            break;
        case TMSDImageCachesManagerOperationPolicySerial: {
            TMSDImageCachesManagerOperation *operation = [TMSDImageCachesManagerOperation new];
            [operation beginWithTotalCount:caches.count];
            [self serialQueryImageForKey:key options:options context:context cacheType:cacheType completion:completionBlock enumerator:caches.reverseObjectEnumerator operation:operation];
            return operation;
        }
            break;
        default:
            return nil;
            break;
    }
}

- (void)storeImage:(UIImage *)image imageData:(NSData *)imageData forKey:(NSString *)key cacheType:(TMSDImageCacheType)cacheType completion:(TMSDWebImageNoParamsBlock)completionBlock {
    if (!key) {
        return;
    }
    NSArray<id<TMSDImageCache>> *caches = self.caches;
    NSUInteger count = caches.count;
    if (count == 0) {
        return;
    } else if (count == 1) {
        [caches.firstObject storeImage:image imageData:imageData forKey:key cacheType:cacheType completion:completionBlock];
        return;
    }
    switch (self.storeOperationPolicy) {
        case TMSDImageCachesManagerOperationPolicyHighestOnly: {
            id<TMSDImageCache> cache = caches.lastObject;
            [cache storeImage:image imageData:imageData forKey:key cacheType:cacheType completion:completionBlock];
        }
            break;
        case TMSDImageCachesManagerOperationPolicyLowestOnly: {
            id<TMSDImageCache> cache = caches.firstObject;
            [cache storeImage:image imageData:imageData forKey:key cacheType:cacheType completion:completionBlock];
        }
            break;
        case TMSDImageCachesManagerOperationPolicyConcurrent: {
            TMSDImageCachesManagerOperation *operation = [TMSDImageCachesManagerOperation new];
            [operation beginWithTotalCount:caches.count];
            [self concurrentStoreImage:image imageData:imageData forKey:key cacheType:cacheType completion:completionBlock enumerator:caches.reverseObjectEnumerator operation:operation];
        }
            break;
        case TMSDImageCachesManagerOperationPolicySerial: {
            [self serialStoreImage:image imageData:imageData forKey:key cacheType:cacheType completion:completionBlock enumerator:caches.reverseObjectEnumerator];
        }
            break;
        default:
            break;
    }
}

- (void)removeImageForKey:(NSString *)key cacheType:(TMSDImageCacheType)cacheType completion:(TMSDWebImageNoParamsBlock)completionBlock {
    if (!key) {
        return;
    }
    NSArray<id<TMSDImageCache>> *caches = self.caches;
    NSUInteger count = caches.count;
    if (count == 0) {
        return;
    } else if (count == 1) {
        [caches.firstObject removeImageForKey:key cacheType:cacheType completion:completionBlock];
        return;
    }
    switch (self.removeOperationPolicy) {
        case TMSDImageCachesManagerOperationPolicyHighestOnly: {
            id<TMSDImageCache> cache = caches.lastObject;
            [cache removeImageForKey:key cacheType:cacheType completion:completionBlock];
        }
            break;
        case TMSDImageCachesManagerOperationPolicyLowestOnly: {
            id<TMSDImageCache> cache = caches.firstObject;
            [cache removeImageForKey:key cacheType:cacheType completion:completionBlock];
        }
            break;
        case TMSDImageCachesManagerOperationPolicyConcurrent: {
            TMSDImageCachesManagerOperation *operation = [TMSDImageCachesManagerOperation new];
            [operation beginWithTotalCount:caches.count];
            [self concurrentRemoveImageForKey:key cacheType:cacheType completion:completionBlock enumerator:caches.reverseObjectEnumerator operation:operation];
        }
            break;
        case TMSDImageCachesManagerOperationPolicySerial: {
            [self serialRemoveImageForKey:key cacheType:cacheType completion:completionBlock enumerator:caches.reverseObjectEnumerator];
        }
            break;
        default:
            break;
    }
}

- (void)containsImageForKey:(NSString *)key cacheType:(TMSDImageCacheType)cacheType completion:(TMSDImageCacheContainsCompletionBlock)completionBlock {
    if (!key) {
        return;
    }
    NSArray<id<TMSDImageCache>> *caches = self.caches;
    NSUInteger count = caches.count;
    if (count == 0) {
        return;
    } else if (count == 1) {
        [caches.firstObject containsImageForKey:key cacheType:cacheType completion:completionBlock];
        return;
    }
    switch (self.clearOperationPolicy) {
        case TMSDImageCachesManagerOperationPolicyHighestOnly: {
            id<TMSDImageCache> cache = caches.lastObject;
            [cache containsImageForKey:key cacheType:cacheType completion:completionBlock];
        }
            break;
        case TMSDImageCachesManagerOperationPolicyLowestOnly: {
            id<TMSDImageCache> cache = caches.firstObject;
            [cache containsImageForKey:key cacheType:cacheType completion:completionBlock];
        }
            break;
        case TMSDImageCachesManagerOperationPolicyConcurrent: {
            TMSDImageCachesManagerOperation *operation = [TMSDImageCachesManagerOperation new];
            [operation beginWithTotalCount:caches.count];
            [self concurrentContainsImageForKey:key cacheType:cacheType completion:completionBlock enumerator:caches.reverseObjectEnumerator operation:operation];
        }
            break;
        case TMSDImageCachesManagerOperationPolicySerial: {
            TMSDImageCachesManagerOperation *operation = [TMSDImageCachesManagerOperation new];
            [operation beginWithTotalCount:caches.count];
            [self serialContainsImageForKey:key cacheType:cacheType completion:completionBlock enumerator:caches.reverseObjectEnumerator operation:operation];
        }
            break;
        default:
            break;
    }
}

- (void)clearWithCacheType:(TMSDImageCacheType)cacheType completion:(TMSDWebImageNoParamsBlock)completionBlock {
    NSArray<id<TMSDImageCache>> *caches = self.caches;
    NSUInteger count = caches.count;
    if (count == 0) {
        return;
    } else if (count == 1) {
        [caches.firstObject clearWithCacheType:cacheType completion:completionBlock];
        return;
    }
    switch (self.clearOperationPolicy) {
        case TMSDImageCachesManagerOperationPolicyHighestOnly: {
            id<TMSDImageCache> cache = caches.lastObject;
            [cache clearWithCacheType:cacheType completion:completionBlock];
        }
            break;
        case TMSDImageCachesManagerOperationPolicyLowestOnly: {
            id<TMSDImageCache> cache = caches.firstObject;
            [cache clearWithCacheType:cacheType completion:completionBlock];
        }
            break;
        case TMSDImageCachesManagerOperationPolicyConcurrent: {
            TMSDImageCachesManagerOperation *operation = [TMSDImageCachesManagerOperation new];
            [operation beginWithTotalCount:caches.count];
            [self concurrentClearWithCacheType:cacheType completion:completionBlock enumerator:caches.reverseObjectEnumerator operation:operation];
        }
            break;
        case TMSDImageCachesManagerOperationPolicySerial: {
            [self serialClearWithCacheType:cacheType completion:completionBlock enumerator:caches.reverseObjectEnumerator];
        }
            break;
        default:
            break;
    }
}

#pragma mark - Concurrent Operation

- (void)concurrentQueryImageForKey:(NSString *)key options:(TMSDWebImageOptions)options context:(TMSDWebImageContext *)context cacheType:(TMSDImageCacheType)queryCacheType completion:(TMSDImageCacheQueryCompletionBlock)completionBlock enumerator:(NSEnumerator<id<TMSDImageCache>> *)enumerator operation:(TMSDImageCachesManagerOperation *)operation {
    NSParameterAssert(enumerator);
    NSParameterAssert(operation);
    for (id<TMSDImageCache> cache in enumerator) {
        [cache queryImageForKey:key options:options context:context cacheType:queryCacheType completion:^(UIImage * _Nullable image, NSData * _Nullable data, TMSDImageCacheType cacheType) {
            if (operation.isCancelled) {
                // Cancelled
                return;
            }
            if (operation.isFinished) {
                // Finished
                return;
            }
            [operation completeOne];
            if (image) {
                // Success
                [operation done];
                if (completionBlock) {
                    completionBlock(image, data, cacheType);
                }
                return;
            }
            if (operation.pendingCount == 0) {
                // Complete
                [operation done];
                if (completionBlock) {
                    completionBlock(nil, nil, TMSDImageCacheTypeNone);
                }
            }
        }];
    }
}

- (void)concurrentStoreImage:(UIImage *)image imageData:(NSData *)imageData forKey:(NSString *)key cacheType:(TMSDImageCacheType)cacheType completion:(TMSDWebImageNoParamsBlock)completionBlock enumerator:(NSEnumerator<id<TMSDImageCache>> *)enumerator operation:(TMSDImageCachesManagerOperation *)operation {
    NSParameterAssert(enumerator);
    NSParameterAssert(operation);
    for (id<TMSDImageCache> cache in enumerator) {
        [cache storeImage:image imageData:imageData forKey:key cacheType:cacheType completion:^{
            if (operation.isCancelled) {
                // Cancelled
                return;
            }
            if (operation.isFinished) {
                // Finished
                return;
            }
            [operation completeOne];
            if (operation.pendingCount == 0) {
                // Complete
                [operation done];
                if (completionBlock) {
                    completionBlock();
                }
            }
        }];
    }
}

- (void)concurrentRemoveImageForKey:(NSString *)key cacheType:(TMSDImageCacheType)cacheType completion:(TMSDWebImageNoParamsBlock)completionBlock enumerator:(NSEnumerator<id<TMSDImageCache>> *)enumerator operation:(TMSDImageCachesManagerOperation *)operation {
    NSParameterAssert(enumerator);
    NSParameterAssert(operation);
    for (id<TMSDImageCache> cache in enumerator) {
        [cache removeImageForKey:key cacheType:cacheType completion:^{
            if (operation.isCancelled) {
                // Cancelled
                return;
            }
            if (operation.isFinished) {
                // Finished
                return;
            }
            [operation completeOne];
            if (operation.pendingCount == 0) {
                // Complete
                [operation done];
                if (completionBlock) {
                    completionBlock();
                }
            }
        }];
    }
}

- (void)concurrentContainsImageForKey:(NSString *)key cacheType:(TMSDImageCacheType)cacheType completion:(TMSDImageCacheContainsCompletionBlock)completionBlock enumerator:(NSEnumerator<id<TMSDImageCache>> *)enumerator operation:(TMSDImageCachesManagerOperation *)operation {
    NSParameterAssert(enumerator);
    NSParameterAssert(operation);
    for (id<TMSDImageCache> cache in enumerator) {
        [cache containsImageForKey:key cacheType:cacheType completion:^(TMSDImageCacheType containsCacheType) {
            if (operation.isCancelled) {
                // Cancelled
                return;
            }
            if (operation.isFinished) {
                // Finished
                return;
            }
            [operation completeOne];
            if (containsCacheType != TMSDImageCacheTypeNone) {
                // Success
                [operation done];
                if (completionBlock) {
                    completionBlock(containsCacheType);
                }
                return;
            }
            if (operation.pendingCount == 0) {
                // Complete
                [operation done];
                if (completionBlock) {
                    completionBlock(TMSDImageCacheTypeNone);
                }
            }
        }];
    }
}

- (void)concurrentClearWithCacheType:(TMSDImageCacheType)cacheType completion:(TMSDWebImageNoParamsBlock)completionBlock enumerator:(NSEnumerator<id<TMSDImageCache>> *)enumerator operation:(TMSDImageCachesManagerOperation *)operation {
    NSParameterAssert(enumerator);
    NSParameterAssert(operation);
    for (id<TMSDImageCache> cache in enumerator) {
        [cache clearWithCacheType:cacheType completion:^{
            if (operation.isCancelled) {
                // Cancelled
                return;
            }
            if (operation.isFinished) {
                // Finished
                return;
            }
            [operation completeOne];
            if (operation.pendingCount == 0) {
                // Complete
                [operation done];
                if (completionBlock) {
                    completionBlock();
                }
            }
        }];
    }
}

#pragma mark - Serial Operation

- (void)serialQueryImageForKey:(NSString *)key options:(TMSDWebImageOptions)options context:(TMSDWebImageContext *)context cacheType:(TMSDImageCacheType)queryCacheType completion:(TMSDImageCacheQueryCompletionBlock)completionBlock enumerator:(NSEnumerator<id<TMSDImageCache>> *)enumerator operation:(TMSDImageCachesManagerOperation *)operation {
    NSParameterAssert(enumerator);
    NSParameterAssert(operation);
    id<TMSDImageCache> cache = enumerator.nextObject;
    if (!cache) {
        // Complete
        [operation done];
        if (completionBlock) {
            completionBlock(nil, nil, TMSDImageCacheTypeNone);
        }
        return;
    }
    @weakify(self);
    [cache queryImageForKey:key options:options context:context cacheType:queryCacheType completion:^(UIImage * _Nullable image, NSData * _Nullable data, TMSDImageCacheType cacheType) {
        @strongify(self);
        if (operation.isCancelled) {
            // Cancelled
            return;
        }
        if (operation.isFinished) {
            // Finished
            return;
        }
        [operation completeOne];
        if (image) {
            // Success
            [operation done];
            if (completionBlock) {
                completionBlock(image, data, cacheType);
            }
            return;
        }
        // Next
        [self serialQueryImageForKey:key options:options context:context cacheType:queryCacheType completion:completionBlock enumerator:enumerator operation:operation];
    }];
}

- (void)serialStoreImage:(UIImage *)image imageData:(NSData *)imageData forKey:(NSString *)key cacheType:(TMSDImageCacheType)cacheType completion:(TMSDWebImageNoParamsBlock)completionBlock enumerator:(NSEnumerator<id<TMSDImageCache>> *)enumerator {
    NSParameterAssert(enumerator);
    id<TMSDImageCache> cache = enumerator.nextObject;
    if (!cache) {
        // Complete
        if (completionBlock) {
            completionBlock();
        }
        return;
    }
    @weakify(self);
    [cache storeImage:image imageData:imageData forKey:key cacheType:cacheType completion:^{
        @strongify(self);
        // Next
        [self serialStoreImage:image imageData:imageData forKey:key cacheType:cacheType completion:completionBlock enumerator:enumerator];
    }];
}

- (void)serialRemoveImageForKey:(NSString *)key cacheType:(TMSDImageCacheType)cacheType completion:(TMSDWebImageNoParamsBlock)completionBlock enumerator:(NSEnumerator<id<TMSDImageCache>> *)enumerator {
    NSParameterAssert(enumerator);
    id<TMSDImageCache> cache = enumerator.nextObject;
    if (!cache) {
        // Complete
        if (completionBlock) {
            completionBlock();
        }
        return;
    }
    @weakify(self);
    [cache removeImageForKey:key cacheType:cacheType completion:^{
        @strongify(self);
        // Next
        [self serialRemoveImageForKey:key cacheType:cacheType completion:completionBlock enumerator:enumerator];
    }];
}

- (void)serialContainsImageForKey:(NSString *)key cacheType:(TMSDImageCacheType)cacheType completion:(TMSDImageCacheContainsCompletionBlock)completionBlock enumerator:(NSEnumerator<id<TMSDImageCache>> *)enumerator operation:(TMSDImageCachesManagerOperation *)operation {
    NSParameterAssert(enumerator);
    NSParameterAssert(operation);
    id<TMSDImageCache> cache = enumerator.nextObject;
    if (!cache) {
        // Complete
        [operation done];
        if (completionBlock) {
            completionBlock(TMSDImageCacheTypeNone);
        }
        return;
    }
    @weakify(self);
    [cache containsImageForKey:key cacheType:cacheType completion:^(TMSDImageCacheType containsCacheType) {
        @strongify(self);
        if (operation.isCancelled) {
            // Cancelled
            return;
        }
        if (operation.isFinished) {
            // Finished
            return;
        }
        [operation completeOne];
        if (containsCacheType != TMSDImageCacheTypeNone) {
            // Success
            [operation done];
            if (completionBlock) {
                completionBlock(containsCacheType);
            }
            return;
        }
        // Next
        [self serialContainsImageForKey:key cacheType:cacheType completion:completionBlock enumerator:enumerator operation:operation];
    }];
}

- (void)serialClearWithCacheType:(TMSDImageCacheType)cacheType completion:(TMSDWebImageNoParamsBlock)completionBlock enumerator:(NSEnumerator<id<TMSDImageCache>> *)enumerator {
    NSParameterAssert(enumerator);
    id<TMSDImageCache> cache = enumerator.nextObject;
    if (!cache) {
        // Complete
        if (completionBlock) {
            completionBlock();
        }
        return;
    }
    @weakify(self);
    [cache clearWithCacheType:cacheType completion:^{
        @strongify(self);
        // Next
        [self serialClearWithCacheType:cacheType completion:completionBlock enumerator:enumerator];
    }];
}

@end
