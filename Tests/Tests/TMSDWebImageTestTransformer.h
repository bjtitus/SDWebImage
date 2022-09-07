/*
 * This file is part of the TMSDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 * (c) Matt Galloway
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import <TMSDWebImage/TMSDImageTransformer.h>

@interface TMSDWebImageTestTransformer : NSObject <TMSDImageTransformer>

@property (nonatomic, strong, nullable) UIImage *testImage;

@end
