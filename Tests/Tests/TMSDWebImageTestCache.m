/*
 * This file is part of the TMSDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 * (c) Matt Galloway
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import <TMSDWebImage/TMSDWebImageTestCache.h>
#import <TMSDWebImage/TMSDWebImage.h>
#import <TMSDWebImage/TMSDFileAttributeHelper.h>

static NSString * const TMSDWebImageTestDiskCacheExtendedAttributeName = @"com.hackemist.TMSDWebImageTestDiskCache";

@implementation TMSDWebImageTestMemoryCache

- (nonnull instancetype)initWithConfig:(nonnull TMSDImageCacheConfig *)config {
    self = [super init];
    if (self) {
        self.config = config;
        self.cache = [[NSCache alloc] init];
    }
    return self;
}

- (nullable id)objectForKey:(nonnull id)key {
    return [self.cache objectForKey:key];
}

- (void)removeAllObjects {
    [self.cache removeAllObjects];
}

- (void)removeObjectForKey:(nonnull id)key {
    [self.cache removeObjectForKey:key];
}

- (void)setObject:(nullable id)object forKey:(nonnull id)key {
    [self.cache setObject:object forKey:key];
}

- (void)setObject:(nullable id)object forKey:(nonnull id)key cost:(NSUInteger)cost {
    [self.cache setObject:object forKey:key cost:cost];
}

@end

@implementation TMSDWebImageTestDiskCache

- (nullable NSString *)cachePathForKey:(nonnull NSString *)key {
    return [self.cachePath stringByAppendingPathComponent:key.lastPathComponent];
}

- (BOOL)containsDataForKey:(nonnull NSString *)key {
    return [self.fileManager fileExistsAtPath:[self cachePathForKey:key]];
}

- (nullable NSData *)dataForKey:(nonnull NSString *)key {
    return [self.fileManager contentsAtPath:[self cachePathForKey:key]];
}

- (nullable instancetype)initWithCachePath:(nonnull NSString *)cachePath config:(nonnull TMSDImageCacheConfig *)config {
    self = [super init];
    if (self) {
        self.cachePath = cachePath;
        self.config = config;
        self.fileManager = config.fileManager ? config.fileManager : [NSFileManager new];
        [self.fileManager createDirectoryAtPath:self.cachePath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    return self;
}

- (void)removeAllData {
    for (NSString *path in [self.fileManager subpathsAtPath:self.cachePath]) {
        NSString *filePath = [self.cachePath stringByAppendingPathComponent:path];
        [self.fileManager removeItemAtPath:filePath error:nil];
    }
}

- (void)removeDataForKey:(nonnull NSString *)key {
    [self.fileManager removeItemAtPath:[self cachePathForKey:key] error:nil];
}

- (void)removeExpiredData {
    NSDate *expirationDate = [NSDate dateWithTimeIntervalSinceNow:-self.config.maxDiskAge];
    for (NSString *fileName in [self.fileManager enumeratorAtPath:self.cachePath]) {
        NSString *filePath = [self.cachePath stringByAppendingPathComponent:fileName];
        NSDate *modificationDate = [[self.fileManager attributesOfItemAtPath:filePath error:nil] objectForKey:NSFileModificationDate];
        if ([[modificationDate laterDate:expirationDate] isEqualToDate:expirationDate]) {
            [self.fileManager removeItemAtPath:filePath error:nil];
        }
    }
}

- (void)setData:(nullable NSData *)data forKey:(nonnull NSString *)key {
    [self.fileManager createFileAtPath:[self cachePathForKey:key] contents:data attributes:nil];
}

- (NSUInteger)totalCount {
    return [self.fileManager contentsOfDirectoryAtPath:self.cachePath error:nil].count;
}

- (NSUInteger)totalSize {
    NSUInteger size = 0;
    for (NSString *fileName in [self.fileManager enumeratorAtPath:self.cachePath]) {
        NSString *filePath = [self.cachePath stringByAppendingPathComponent:fileName];
        size += [[[self.fileManager attributesOfItemAtPath:filePath error:nil] objectForKey:NSFileSize] unsignedIntegerValue];
    }
    return size;
}

- (nullable NSData *)extendedDataForKey:(nonnull NSString *)key {
    NSString *cachePathForKey = [self cachePathForKey:key];
    return [TMSDFileAttributeHelper extendedAttribute:TMSDWebImageTestDiskCacheExtendedAttributeName atPath:cachePathForKey traverseLink:NO error:nil];
}

- (void)setExtendedData:(nullable NSData *)extendedData forKey:(nonnull NSString *)key {
    NSString *cachePathForKey = [self cachePathForKey:key];
    if (!extendedData) {
        [TMSDFileAttributeHelper removeExtendedAttribute:TMSDWebImageTestDiskCacheExtendedAttributeName atPath:cachePathForKey traverseLink:NO error:nil];
    } else {
        [TMSDFileAttributeHelper setExtendedAttribute:TMSDWebImageTestDiskCacheExtendedAttributeName value:extendedData atPath:cachePathForKey traverseLink:NO overwrite:YES error:nil];
    }
}

@end

@implementation TMSDWebImageTestCache

+ (TMSDWebImageTestCache *)sharedCache {
    static dispatch_once_t onceToken;
    static TMSDWebImageTestCache *cache;
    dispatch_once(&onceToken, ^{
        NSString *cachePath = [[self userCacheDirectory] stringByAppendingPathComponent:@"TMSDWebImageTestCache"];
        TMSDImageCacheConfig *config = TMSDImageCacheConfig.defaultCacheConfig;
        cache = [[TMSDWebImageTestCache alloc] initWithCachePath:cachePath config:config];
    });
    return cache;
}

- (instancetype)initWithCachePath:(NSString *)cachePath config:(TMSDImageCacheConfig *)config {
    self = [super init];
    if (self) {
        self.config = config;
        self.memoryCache = [[TMSDWebImageTestMemoryCache alloc] initWithConfig:config];
        self.diskCache = [[TMSDWebImageTestDiskCache alloc] initWithCachePath:cachePath config:config];
    }
    return self;
}

- (void)clearWithCacheType:(TMSDImageCacheType)cacheType completion:(nullable TMSDWebImageNoParamsBlock)completionBlock {
    switch (cacheType) {
        case TMSDImageCacheTypeNone:
            break;
        case TMSDImageCacheTypeMemory:
            [self.memoryCache removeAllObjects];
            break;
        case TMSDImageCacheTypeDisk:
            [self.diskCache removeAllData];
            break;
        case TMSDImageCacheTypeAll:
            [self.memoryCache removeAllObjects];
            [self.diskCache removeAllData];
            break;
        default:
            break;
    }
    if (completionBlock) {
        completionBlock();
    }
}

- (void)containsImageForKey:(nullable NSString *)key cacheType:(TMSDImageCacheType)cacheType completion:(nullable TMSDImageCacheContainsCompletionBlock)completionBlock {
    TMSDImageCacheType containsCacheType = TMSDImageCacheTypeNone;
    switch (cacheType) {
        case TMSDImageCacheTypeNone:
            break;
        case TMSDImageCacheTypeMemory:
            containsCacheType = [self.memoryCache objectForKey:key] ? TMSDImageCacheTypeMemory : TMSDImageCacheTypeNone;
            break;
        case TMSDImageCacheTypeDisk:
            containsCacheType = [self.diskCache containsDataForKey:key] ? TMSDImageCacheTypeDisk : TMSDImageCacheTypeNone;
            break;
        case TMSDImageCacheTypeAll:
            if ([self.memoryCache objectForKey:key]) {
                containsCacheType = TMSDImageCacheTypeMemory;
            } else if ([self.diskCache containsDataForKey:key]) {
                containsCacheType = TMSDImageCacheTypeDisk;
            }
            break;
        default:
            break;
    }
    if (completionBlock) {
        completionBlock(containsCacheType);
    }
}

- (nullable id<TMSDWebImageOperation>)queryImageForKey:(nullable NSString *)key options:(TMSDWebImageOptions)options context:(nullable TMSDWebImageContext *)context completion:(nullable TMSDImageCacheQueryCompletionBlock)completionBlock {
    return [self queryImageForKey:key options:options context:context cacheType:TMSDImageCacheTypeAll completion:completionBlock];
}

- (nullable id<TMSDWebImageOperation>)queryImageForKey:(nullable NSString *)key options:(TMSDWebImageOptions)options context:(nullable TMSDWebImageContext *)context cacheType:(TMSDImageCacheType)cacheType completion:(nullable TMSDImageCacheQueryCompletionBlock)completionBlock {
    UIImage *image;
    NSData *data;
    TMSDImageCacheType resultCacheType = TMSDImageCacheTypeNone;
    switch (cacheType) {
        case TMSDImageCacheTypeNone:
            break;
        case TMSDImageCacheTypeMemory:
            image = [self.memoryCache objectForKey:key];
            if (image) {
                resultCacheType = TMSDImageCacheTypeMemory;
            }
            break;
        case TMSDImageCacheTypeDisk:
            data = [self.diskCache dataForKey:key];
            image = [UIImage tmsd_imageWithData:data];
            if (data) {
                resultCacheType = TMSDImageCacheTypeDisk;
            }
            break;
        case TMSDImageCacheTypeAll:
            image = [self.memoryCache objectForKey:key];
            if (image) {
                resultCacheType = TMSDImageCacheTypeMemory;
            } else {
                data = [self.diskCache dataForKey:key];
                image = [UIImage tmsd_imageWithData:data];
                if (data) {
                    resultCacheType = TMSDImageCacheTypeDisk;
                }
            }
            break;
        default:
            break;
    }
    if (completionBlock) {
        completionBlock(image, data, resultCacheType);
    }
    return nil;
}

- (void)removeImageForKey:(nullable NSString *)key cacheType:(TMSDImageCacheType)cacheType completion:(nullable TMSDWebImageNoParamsBlock)completionBlock {
    switch (cacheType) {
        case TMSDImageCacheTypeNone:
            break;
        case TMSDImageCacheTypeMemory:
            [self.memoryCache removeObjectForKey:key];
            break;
        case TMSDImageCacheTypeDisk:
            [self.diskCache removeDataForKey:key];
            break;
        case TMSDImageCacheTypeAll:
            [self.memoryCache removeObjectForKey:key];
            [self.diskCache removeDataForKey:key];
            break;
        default:
            break;
    }
    if (completionBlock) {
        completionBlock();
    }
}

- (void)storeImage:(nullable UIImage *)image imageData:(nullable NSData *)imageData forKey:(nullable NSString *)key cacheType:(TMSDImageCacheType)cacheType completion:(nullable TMSDWebImageNoParamsBlock)completionBlock {
    switch (cacheType) {
        case TMSDImageCacheTypeNone:
            break;
        case TMSDImageCacheTypeMemory:
            [self.memoryCache setObject:image forKey:key];
            break;
        case TMSDImageCacheTypeDisk:
            [self.diskCache setData:imageData forKey:key];
            break;
        case TMSDImageCacheTypeAll:
            [self.memoryCache setObject:image forKey:key];
            [self.diskCache setData:imageData forKey:key];
            break;
        default:
            break;
    }
    if (completionBlock) {
        completionBlock();
    }
}

+ (nullable NSString *)userCacheDirectory {
    NSArray<NSString *> *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    return paths.firstObject;
}

@end
