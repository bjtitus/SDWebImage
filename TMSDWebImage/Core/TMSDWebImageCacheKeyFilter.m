/*
 * This file is part of the TMSDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import <TMSDWebImage/TMSDWebImageCacheKeyFilter.h>

@interface TMSDWebImageCacheKeyFilter ()

@property (nonatomic, copy, nonnull) TMSDWebImageCacheKeyFilterBlock block;

@end

@implementation TMSDWebImageCacheKeyFilter

- (instancetype)initWithBlock:(TMSDWebImageCacheKeyFilterBlock)block {
    self = [super init];
    if (self) {
        self.block = block;
    }
    return self;
}

+ (instancetype)cacheKeyFilterWithBlock:(TMSDWebImageCacheKeyFilterBlock)block {
    TMSDWebImageCacheKeyFilter *cacheKeyFilter = [[TMSDWebImageCacheKeyFilter alloc] initWithBlock:block];
    return cacheKeyFilter;
}

- (NSString *)cacheKeyForURL:(NSURL *)url {
    if (!self.block) {
        return nil;
    }
    return self.block(url);
}

@end
