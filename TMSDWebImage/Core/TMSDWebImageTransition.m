/*
 * This file is part of the TMSDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import <TMSDWebImage/TMSDWebImageTransition.h>

#if TMSD_UIKIT || TMSD_MAC

#if TMSD_MAC
#import <TMSDWebImage/TMSDWebImageTransitionInternal.h>
#import <TMSDWebImage/TMSDInternalMacros.h>

CAMediaTimingFunction * TMSDTimingFunctionFromAnimationOptions(TMSDWebImageAnimationOptions options) {
    if (TMSD_OPTIONS_CONTAINS(TMSDWebImageAnimationOptionCurveLinear, options)) {
        return [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
    } else if (TMSD_OPTIONS_CONTAINS(TMSDWebImageAnimationOptionCurveEaseIn, options)) {
        return [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn];
    } else if (TMSD_OPTIONS_CONTAINS(TMSDWebImageAnimationOptionCurveEaseOut, options)) {
        return [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
    } else if (TMSD_OPTIONS_CONTAINS(TMSDWebImageAnimationOptionCurveEaseInOut, options)) {
        return [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    } else {
        return [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionDefault];
    }
}

CATransition * TMSDTransitionFromAnimationOptions(TMSDWebImageAnimationOptions options) {
    if (TMSD_OPTIONS_CONTAINS(options, TMSDWebImageAnimationOptionTransitionCrossDissolve)) {
        CATransition *trans = [CATransition animation];
        trans.type = kCATransitionFade;
        return trans;
    } else if (TMSD_OPTIONS_CONTAINS(options, TMSDWebImageAnimationOptionTransitionFlipFromLeft)) {
        CATransition *trans = [CATransition animation];
        trans.type = kCATransitionPush;
        trans.subtype = kCATransitionFromLeft;
        return trans;
    } else if (TMSD_OPTIONS_CONTAINS(options, TMSDWebImageAnimationOptionTransitionFlipFromRight)) {
        CATransition *trans = [CATransition animation];
        trans.type = kCATransitionPush;
        trans.subtype = kCATransitionFromRight;
        return trans;
    } else if (TMSD_OPTIONS_CONTAINS(options, TMSDWebImageAnimationOptionTransitionFlipFromTop)) {
        CATransition *trans = [CATransition animation];
        trans.type = kCATransitionPush;
        trans.subtype = kCATransitionFromTop;
        return trans;
    } else if (TMSD_OPTIONS_CONTAINS(options, TMSDWebImageAnimationOptionTransitionFlipFromBottom)) {
        CATransition *trans = [CATransition animation];
        trans.type = kCATransitionPush;
        trans.subtype = kCATransitionFromBottom;
        return trans;
    } else if (TMSD_OPTIONS_CONTAINS(options, TMSDWebImageAnimationOptionTransitionCurlUp)) {
        CATransition *trans = [CATransition animation];
        trans.type = kCATransitionReveal;
        trans.subtype = kCATransitionFromTop;
        return trans;
    } else if (TMSD_OPTIONS_CONTAINS(options, TMSDWebImageAnimationOptionTransitionCurlDown)) {
        CATransition *trans = [CATransition animation];
        trans.type = kCATransitionReveal;
        trans.subtype = kCATransitionFromBottom;
        return trans;
    } else {
        return nil;
    }
}
#endif

@implementation TMSDWebImageTransition

- (instancetype)init {
    self = [super init];
    if (self) {
        self.duration = 0.5;
    }
    return self;
}

@end

@implementation TMSDWebImageTransition (TMSDConveniences)

+ (TMSDWebImageTransition *)fadeTransition {
    return [self fadeTransitionWithDuration:0.5];
}

+ (TMSDWebImageTransition *)fadeTransitionWithDuration:(NSTimeInterval)duration {
    TMSDWebImageTransition *transition = [TMSDWebImageTransition new];
    transition.duration = duration;
#if TMSD_UIKIT
    transition.animationOptions = UIViewAnimationOptionTransitionCrossDissolve | UIViewAnimationOptionAllowUserInteraction;
#else
    transition.animationOptions = TMSDWebImageAnimationOptionTransitionCrossDissolve;
#endif
    return transition;
}

+ (TMSDWebImageTransition *)flipFromLeftTransition {
    return [self flipFromLeftTransitionWithDuration:0.5];
}

+ (TMSDWebImageTransition *)flipFromLeftTransitionWithDuration:(NSTimeInterval)duration {
    TMSDWebImageTransition *transition = [TMSDWebImageTransition new];
    transition.duration = duration;
#if TMSD_UIKIT
    transition.animationOptions = UIViewAnimationOptionTransitionFlipFromLeft | UIViewAnimationOptionAllowUserInteraction;
#else
    transition.animationOptions = TMSDWebImageAnimationOptionTransitionFlipFromLeft;
#endif
    return transition;
}

+ (TMSDWebImageTransition *)flipFromRightTransition {
    return [self flipFromRightTransitionWithDuration:0.5];
}

+ (TMSDWebImageTransition *)flipFromRightTransitionWithDuration:(NSTimeInterval)duration {
    TMSDWebImageTransition *transition = [TMSDWebImageTransition new];
    transition.duration = duration;
#if TMSD_UIKIT
    transition.animationOptions = UIViewAnimationOptionTransitionFlipFromRight | UIViewAnimationOptionAllowUserInteraction;
#else
    transition.animationOptions = TMSDWebImageAnimationOptionTransitionFlipFromRight;
#endif
    return transition;
}

+ (TMSDWebImageTransition *)flipFromTopTransition {
    return [self flipFromTopTransitionWithDuration:0.5];
}

+ (TMSDWebImageTransition *)flipFromTopTransitionWithDuration:(NSTimeInterval)duration {
    TMSDWebImageTransition *transition = [TMSDWebImageTransition new];
    transition.duration = duration;
#if TMSD_UIKIT
    transition.animationOptions = UIViewAnimationOptionTransitionFlipFromTop | UIViewAnimationOptionAllowUserInteraction;
#else
    transition.animationOptions = TMSDWebImageAnimationOptionTransitionFlipFromTop;
#endif
    return transition;
}

+ (TMSDWebImageTransition *)flipFromBottomTransition {
    return [self flipFromBottomTransitionWithDuration:0.5];
}

+ (TMSDWebImageTransition *)flipFromBottomTransitionWithDuration:(NSTimeInterval)duration {
    TMSDWebImageTransition *transition = [TMSDWebImageTransition new];
    transition.duration = duration;
#if TMSD_UIKIT
    transition.animationOptions = UIViewAnimationOptionTransitionFlipFromBottom | UIViewAnimationOptionAllowUserInteraction;
#else
    transition.animationOptions = TMSDWebImageAnimationOptionTransitionFlipFromBottom;
#endif
    return transition;
}

+ (TMSDWebImageTransition *)curlUpTransition {
    return [self curlUpTransitionWithDuration:0.5];
}

+ (TMSDWebImageTransition *)curlUpTransitionWithDuration:(NSTimeInterval)duration {
    TMSDWebImageTransition *transition = [TMSDWebImageTransition new];
    transition.duration = duration;
#if TMSD_UIKIT
    transition.animationOptions = UIViewAnimationOptionTransitionCurlUp | UIViewAnimationOptionAllowUserInteraction;
#else
    transition.animationOptions = TMSDWebImageAnimationOptionTransitionCurlUp;
#endif
    return transition;
}

+ (TMSDWebImageTransition *)curlDownTransition {
    return [self curlDownTransitionWithDuration:0.5];
}

+ (TMSDWebImageTransition *)curlDownTransitionWithDuration:(NSTimeInterval)duration {
    TMSDWebImageTransition *transition = [TMSDWebImageTransition new];
    transition.duration = duration;
#if TMSD_UIKIT
    transition.animationOptions = UIViewAnimationOptionTransitionCurlDown | UIViewAnimationOptionAllowUserInteraction;
#else
    transition.animationOptions = TMSDWebImageAnimationOptionTransitionCurlDown;
#endif
    transition.duration = duration;
    return transition;
}

@end

#endif
