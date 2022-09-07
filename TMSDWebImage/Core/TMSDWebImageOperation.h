/*
 * This file is part of the TMSDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import <Foundation/Foundation.h>

/// A protocol represents cancelable operation.
@protocol TMSDWebImageOperation <NSObject>

/// Cancel the operation
- (void)cancel;

@optional

/// Whether the operation has been cancelled.
@property (nonatomic, assign, readonly, getter=isCancelled) BOOL cancelled;

@end

/// NSOperation conform to `TMSDWebImageOperation`.
@interface NSOperation (TMSDTMSDWebImageOperation) <TMSDWebImageOperation>

@end
