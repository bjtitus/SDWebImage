/*
 * This file is part of the TMSDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 * (c) Matt Galloway
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import <TMSDWebImage/TMSDWebImageTestDownloadOperation.h>

@interface TMSDWebImageTestDownloadOperation ()

@property (nonatomic, strong) NSMutableArray<TMSDWebImageDownloaderCompletedBlock> *completedBlocks;

@end

@implementation TMSDWebImageTestDownloadOperation

@synthesize executing = _executing;
@synthesize finished = _finished;

- (void)start {
    self.finished = NO;
    self.executing = YES;
    // Do nothing but keep running
}

- (void)cancel {
    if (self.isFinished) return;
    [super cancel];
    
    NSError *error = [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorCancelled userInfo:nil];
    for (TMSDWebImageDownloaderCompletedBlock completedBlock in self.completedBlocks) {
        completedBlock(nil, nil, error, YES);
    }
}

- (BOOL)isConcurrent {
    return YES;
}

- (void)setFinished:(BOOL)finished {
    [self willChangeValueForKey:@"isFinished"];
    _finished = finished;
    [self didChangeValueForKey:@"isFinished"];
}

- (void)setExecuting:(BOOL)executing {
    [self willChangeValueForKey:@"isExecuting"];
    _executing = executing;
    [self didChangeValueForKey:@"isExecuting"];
}

- (instancetype)initWithRequest:(NSURLRequest *)request inSession:(NSURLSession *)session options:(TMSDWebImageDownloaderOptions)options {
    return [self initWithRequest:request inSession:session options:options context:nil];
}

- (instancetype)initWithRequest:(NSURLRequest *)request inSession:(NSURLSession *)session options:(TMSDWebImageDownloaderOptions)options context:(TMSDWebImageContext *)context {
    self = [super init];
    if (self) {
        self.request = request;
        self.completedBlocks = [NSMutableArray array];
    }
    return self;
}

- (nullable id)addHandlersForProgress:(nullable TMSDWebImageDownloaderProgressBlock)progressBlock
                            completed:(nullable TMSDWebImageDownloaderCompletedBlock)completedBlock {
    if (completedBlock) {
        [self.completedBlocks addObject:completedBlock];
    }
    return NSStringFromClass([self class]);
}

- (BOOL)cancel:(id)token {
    [self cancel];
    return YES;
}

@end
