/*
 * This file is part of the TMSDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import <TMSDWebImage/TMSDWebImageOptionsProcessor.h>

@interface TMSDWebImageOptionsResult ()

@property (nonatomic, assign) TMSDWebImageOptions options;
@property (nonatomic, copy, nullable) TMSDWebImageContext *context;

@end

@implementation TMSDWebImageOptionsResult

- (instancetype)initWithOptions:(TMSDWebImageOptions)options context:(TMSDWebImageContext *)context {
    self = [super init];
    if (self) {
        self.options = options;
        self.context = context;
    }
    return self;
}

@end

@interface TMSDWebImageOptionsProcessor ()

@property (nonatomic, copy, nonnull) TMSDWebImageOptionsProcessorBlock block;

@end

@implementation TMSDWebImageOptionsProcessor

- (instancetype)initWithBlock:(TMSDWebImageOptionsProcessorBlock)block {
    self = [super init];
    if (self) {
        self.block = block;
    }
    return self;
}

+ (instancetype)optionsProcessorWithBlock:(TMSDWebImageOptionsProcessorBlock)block {
    TMSDWebImageOptionsProcessor *optionsProcessor = [[TMSDWebImageOptionsProcessor alloc] initWithBlock:block];
    return optionsProcessor;
}

- (TMSDWebImageOptionsResult *)processedResultForURL:(NSURL *)url options:(TMSDWebImageOptions)options context:(TMSDWebImageContext *)context {
    if (!self.block) {
        return nil;
    }
    return self.block(url, options, context);
}

@end
