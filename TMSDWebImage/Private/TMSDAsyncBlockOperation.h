/*
 * This file is part of the TMSDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import <TMSDWebImage/TMSDWebImageCompat.h>

@class TMSDAsyncBlockOperation;
typedef void (^TMSDAsyncBlock)(TMSDAsyncBlockOperation * __nonnull asyncOperation);

/// A async block operation, success after you call `completer` (not like `NSBlockOperation` which is for sync block, success on return)
@interface TMSDAsyncBlockOperation : NSOperation

- (nonnull instancetype)initWithBlock:(nonnull TMSDAsyncBlock)block;
+ (nonnull instancetype)blockOperationWithBlock:(nonnull TMSDAsyncBlock)block;
- (void)complete;

@end
