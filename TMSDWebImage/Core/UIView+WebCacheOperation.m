/*
 * This file is part of the TMSDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import <TMSDWebImage/UIView+WebCacheOperation.h>
#import "objc/runtime.h"

// key is strong, value is weak because operation instance is retained by TMSDWebImageManager's runningOperations property
// we should use lock to keep thread-safe because these method may not be accessed from main queue
typedef NSMapTable<NSString *, id<TMSDWebImageOperation>> TMSDOperationsDictionary;

@implementation UIView (TMSDWebCacheOperation)

- (TMSDOperationsDictionary *)tmsd_operationDictionary {
    @synchronized(self) {
        TMSDOperationsDictionary *operations = objc_getAssociatedObject(self, @selector(tmsd_operationDictionary));
        if (operations) {
            return operations;
        }
        operations = [[NSMapTable alloc] initWithKeyOptions:NSPointerFunctionsStrongMemory valueOptions:NSPointerFunctionsWeakMemory capacity:0];
        objc_setAssociatedObject(self, @selector(tmsd_operationDictionary), operations, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        return operations;
    }
}

- (nullable id<TMSDWebImageOperation>)tmsd_imageLoadOperationForKey:(nullable NSString *)key  {
    id<TMSDWebImageOperation> operation;
    if (key) {
        TMSDOperationsDictionary *operationDictionary = [self tmsd_operationDictionary];
        @synchronized (self) {
            operation = [operationDictionary objectForKey:key];
        }
    }
    return operation;
}

- (void)tmsd_setImageLoadOperation:(nullable id<TMSDWebImageOperation>)operation forKey:(nullable NSString *)key {
    if (key) {
        [self tmsd_cancelImageLoadOperationWithKey:key];
        if (operation) {
            TMSDOperationsDictionary *operationDictionary = [self tmsd_operationDictionary];
            @synchronized (self) {
                [operationDictionary setObject:operation forKey:key];
            }
        }
    }
}

- (void)tmsd_cancelImageLoadOperationWithKey:(nullable NSString *)key {
    if (key) {
        // Cancel in progress downloader from queue
        TMSDOperationsDictionary *operationDictionary = [self tmsd_operationDictionary];
        id<TMSDWebImageOperation> operation;
        
        @synchronized (self) {
            operation = [operationDictionary objectForKey:key];
        }
        if (operation) {
            if ([operation conformsToProtocol:@protocol(TMSDWebImageOperation)]) {
                [operation cancel];
            }
            @synchronized (self) {
                [operationDictionary removeObjectForKey:key];
            }
        }
    }
}

- (void)tmsd_removeImageLoadOperationWithKey:(nullable NSString *)key {
    if (key) {
        TMSDOperationsDictionary *operationDictionary = [self tmsd_operationDictionary];
        @synchronized (self) {
            [operationDictionary removeObjectForKey:key];
        }
    }
}

@end
