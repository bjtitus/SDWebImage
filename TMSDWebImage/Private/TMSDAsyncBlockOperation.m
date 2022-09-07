/*
 * This file is part of the TMSDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import <TMSDWebImage/TMSDAsyncBlockOperation.h>

@interface TMSDAsyncBlockOperation ()

@property (assign, nonatomic, getter = isExecuting) BOOL executing;
@property (assign, nonatomic, getter = isFinished) BOOL finished;
@property (nonatomic, copy, nonnull) TMSDAsyncBlock executionBlock;

@end

@implementation TMSDAsyncBlockOperation

@synthesize executing = _executing;
@synthesize finished = _finished;

- (nonnull instancetype)initWithBlock:(nonnull TMSDAsyncBlock)block {
    self = [super init];
    if (self) {
        self.executionBlock = block;
    }
    return self;
}

+ (nonnull instancetype)blockOperationWithBlock:(nonnull TMSDAsyncBlock)block {
    TMSDAsyncBlockOperation *operation = [[TMSDAsyncBlockOperation alloc] initWithBlock:block];
    return operation;
}

- (void)start {
    @synchronized (self) {
        if (self.isCancelled) {
            self.finished = YES;
            return;
        }
        
        self.finished = NO;
        self.executing = YES;
        
        if (self.executionBlock) {
            self.executionBlock(self);
        } else {
            self.executing = NO;
            self.finished = YES;
        }
    }
}

- (void)cancel {
    @synchronized (self) {
        [super cancel];
        if (self.isExecuting) {
            self.executing = NO;
            self.finished = YES;
        }
    }
}

 
- (void)complete {
    @synchronized (self) {
        if (self.isExecuting) {
            self.finished = YES;
            self.executing = NO;
        }
    }
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

- (BOOL)isConcurrent {
    return YES;
}

@end
