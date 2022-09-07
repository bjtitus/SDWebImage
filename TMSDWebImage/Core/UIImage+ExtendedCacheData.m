/*
* This file is part of the TMSDWebImage package.
* (c) Olivier Poitrey <rs@dailymotion.com>
* (c) Fabrice Aneche
*
* For the full copyright and license information, please view the LICENSE
* file that was distributed with this source code.
*/

#import <TMSDWebImage/UIImage+ExtendedCacheData.h>
#import <objc/runtime.h>

@implementation UIImage (TMSDExtendedCacheData)

- (id<NSObject, NSCoding>)tmsd_extendedObject {
    return objc_getAssociatedObject(self, @selector(tmsd_extendedObject));
}

- (void)setTmsd_extendedObject:(id<NSObject, NSCoding>)tmsd_extendedObject {
    objc_setAssociatedObject(self, @selector(tmsd_extendedObject), tmsd_extendedObject, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end
