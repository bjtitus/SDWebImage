/*
 * This file is part of the TMSDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 * (c) Matt Galloway
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import <Foundation/Foundation.h>
#import <TMSDWebImage/TMSDImageLoader.h>

// A really naive implementation of custom image loader using `NSURLSession`
@interface TMSDWebImageTestLoader : NSObject <TMSDImageLoader>

@property (nonatomic, class, readonly, nonnull) TMSDWebImageTestLoader *sharedLoader;

@end
