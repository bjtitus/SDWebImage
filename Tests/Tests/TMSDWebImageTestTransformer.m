/*
 * This file is part of the TMSDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 * (c) Matt Galloway
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import <TMSDWebImage/TMSDWebImageTestTransformer.h>

@implementation TMSDWebImageTestTransformer

- (NSString *)transformerKey {
    return @"TMSDWebImageTestTransformer";
}

- (UIImage *)transformedImageWithImage:(UIImage *)image forKey:(NSString *)key {
    return self.testImage;
}

@end
