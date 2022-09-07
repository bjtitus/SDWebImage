/*
 * This file is part of the TMSDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 * (c) Matt Galloway
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import <Foundation/Foundation.h>
#import <TMSDWebImage/TMSDWebImageDownloaderOperation.h>

/**
 *  A class that fits the NSOperation+TMSDWebImageDownloaderOperation requirement so we can test
 */
@interface TMSDWebImageTestDownloadOperation : NSOperation <TMSDWebImageDownloaderOperation>

@property (nonatomic, strong, nullable) NSURLRequest *request;
@property (nonatomic, strong, nullable) NSURLResponse *response;

@end
