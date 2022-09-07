/*
* This file is part of the TMSDWebImage package.
* (c) Olivier Poitrey <rs@dailymotion.com>
*
* For the full copyright and license information, please view the LICENSE
* file that was distributed with this source code.
*/

#import <TMSDWebImage/TMSDWebImageCompat.h>

#if TMSD_MAC

#import <QuartzCore/QuartzCore.h>

/// Helper method for Core Animation transition
FOUNDATION_EXPORT CAMediaTimingFunction * _Nullable TMSDTimingFunctionFromAnimationOptions(TMSDWebImageAnimationOptions options);
FOUNDATION_EXPORT CATransition * _Nullable TMSDTransitionFromAnimationOptions(TMSDWebImageAnimationOptions options);

#endif
