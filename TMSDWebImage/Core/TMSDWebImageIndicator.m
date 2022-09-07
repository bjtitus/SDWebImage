/*
 * This file is part of the TMSDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import <TMSDWebImage/TMSDWebImageIndicator.h>

#if TMSD_UIKIT || TMSD_MAC

#if TMSD_MAC
#import <QuartzCore/QuartzCore.h>
#import <CoreImage/CIFilter.h>
#endif

#pragma mark - Activity Indicator

@interface TMSDWebImageActivityIndicator ()

#if TMSD_UIKIT
@property (nonatomic, strong, readwrite, nonnull) UIActivityIndicatorView *indicatorView;
#else
@property (nonatomic, strong, readwrite, nonnull) NSProgressIndicator *indicatorView;
#endif

@end

@implementation TMSDWebImageActivityIndicator

- (instancetype)init {
    self = [super init];
    if (self) {
        [self commonInit];
    }
    return self;
}

#if TMSD_UIKIT
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
- (void)commonInit {
    self.indicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    self.indicatorView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin;
}
#pragma clang diagnostic pop
#endif

#if TMSD_MAC
- (void)commonInit {
    self.indicatorView = [[NSProgressIndicator alloc] initWithFrame:NSZeroRect];
    self.indicatorView.style = NSProgressIndicatorStyleSpinning;
    self.indicatorView.controlSize = NSControlSizeSmall;
    [self.indicatorView sizeToFit];
    self.indicatorView.autoresizingMask = NSViewMaxXMargin | NSViewMinXMargin | NSViewMaxYMargin | NSViewMinYMargin;
}
#endif

- (void)startAnimatingIndicator {
#if TMSD_UIKIT
    [self.indicatorView startAnimating];
#else
    [self.indicatorView startAnimation:nil];
#endif
    self.indicatorView.hidden = NO;
}

- (void)stopAnimatingIndicator {
#if TMSD_UIKIT
    [self.indicatorView stopAnimating];
#else
    [self.indicatorView stopAnimation:nil];
#endif
    self.indicatorView.hidden = YES;
}

@end

@implementation TMSDWebImageActivityIndicator (TMSDConveniences)

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
+ (TMSDWebImageActivityIndicator *)grayIndicator {
    TMSDWebImageActivityIndicator *indicator = [TMSDWebImageActivityIndicator new];
#if TMSD_UIKIT
#if TMSD_IOS
    indicator.indicatorView.activityIndicatorViewStyle = UIActivityIndicatorViewStyleGray;
#else
    indicator.indicatorView.color = [UIColor colorWithWhite:0 alpha:0.45]; // Color from `UIActivityIndicatorViewStyleGray`
#endif
#else
    indicator.indicatorView.appearance = [NSAppearance appearanceNamed:NSAppearanceNameAqua]; // Disable dark mode support
#endif
    return indicator;
}

+ (TMSDWebImageActivityIndicator *)grayLargeIndicator {
    TMSDWebImageActivityIndicator *indicator = TMSDWebImageActivityIndicator.grayIndicator;
#if TMSD_UIKIT
    UIColor *grayColor = indicator.indicatorView.color;
    indicator.indicatorView.activityIndicatorViewStyle = UIActivityIndicatorViewStyleWhiteLarge;
    indicator.indicatorView.color = grayColor;
#else
    indicator.indicatorView.appearance = [NSAppearance appearanceNamed:NSAppearanceNameAqua]; // Disable dark mode support
    indicator.indicatorView.controlSize = NSControlSizeRegular;
#endif
    [indicator.indicatorView sizeToFit];
    return indicator;
}

+ (TMSDWebImageActivityIndicator *)whiteIndicator {
    TMSDWebImageActivityIndicator *indicator = [TMSDWebImageActivityIndicator new];
#if TMSD_UIKIT
    indicator.indicatorView.activityIndicatorViewStyle = UIActivityIndicatorViewStyleWhite;
#else
    indicator.indicatorView.appearance = [NSAppearance appearanceNamed:NSAppearanceNameAqua]; // Disable dark mode support
    CIFilter *lighten = [CIFilter filterWithName:@"CIColorControls"];
    [lighten setDefaults];
    [lighten setValue:@(1) forKey:kCIInputBrightnessKey];
    indicator.indicatorView.contentFilters = @[lighten];
#endif
    return indicator;
}

+ (TMSDWebImageActivityIndicator *)whiteLargeIndicator {
    TMSDWebImageActivityIndicator *indicator = TMSDWebImageActivityIndicator.whiteIndicator;
#if TMSD_UIKIT
    indicator.indicatorView.activityIndicatorViewStyle = UIActivityIndicatorViewStyleWhiteLarge;
#else
    indicator.indicatorView.appearance = [NSAppearance appearanceNamed:NSAppearanceNameAqua]; // Disable dark mode support
    indicator.indicatorView.controlSize = NSControlSizeRegular;
    [indicator.indicatorView sizeToFit];
#endif
    return indicator;
}

+ (TMSDWebImageActivityIndicator *)largeIndicator {
    TMSDWebImageActivityIndicator *indicator = [TMSDWebImageActivityIndicator new];
#if TMSD_UIKIT
    if (@available(iOS 13.0, tvOS 13.0, *)) {
        indicator.indicatorView.activityIndicatorViewStyle = UIActivityIndicatorViewStyleLarge;
    } else {
        indicator.indicatorView.activityIndicatorViewStyle = UIActivityIndicatorViewStyleWhiteLarge;
    }
#else
    indicator.indicatorView.controlSize = NSControlSizeRegular;
    [indicator.indicatorView sizeToFit];
#endif
    return indicator;
}

+ (TMSDWebImageActivityIndicator *)mediumIndicator {
    TMSDWebImageActivityIndicator *indicator = [TMSDWebImageActivityIndicator new];
#if TMSD_UIKIT
    if (@available(iOS 13.0, tvOS 13.0, *)) {
        indicator.indicatorView.activityIndicatorViewStyle = UIActivityIndicatorViewStyleMedium;
    } else {
        indicator.indicatorView.activityIndicatorViewStyle = UIActivityIndicatorViewStyleWhite;
    }
#else
    indicator.indicatorView.controlSize = NSControlSizeSmall;
    [indicator.indicatorView sizeToFit];
#endif
    return indicator;
}
#pragma clang diagnostic pop

@end

#pragma mark - Progress Indicator

@interface TMSDWebImageProgressIndicator ()

#if TMSD_UIKIT
@property (nonatomic, strong, readwrite, nonnull) UIProgressView *indicatorView;
#else
@property (nonatomic, strong, readwrite, nonnull) NSProgressIndicator *indicatorView;
#endif

@end

@implementation TMSDWebImageProgressIndicator

- (instancetype)init {
    self = [super init];
    if (self) {
        [self commonInit];
    }
    return self;
}

#if TMSD_UIKIT
- (void)commonInit {
    self.indicatorView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
    self.indicatorView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin;
}
#endif

#if TMSD_MAC
- (void)commonInit {
    self.indicatorView = [[NSProgressIndicator alloc] initWithFrame:NSMakeRect(0, 0, 160, 0)]; // Width from `UIProgressView` default width
    self.indicatorView.style = NSProgressIndicatorStyleBar;
    self.indicatorView.controlSize = NSControlSizeSmall;
    [self.indicatorView sizeToFit];
    self.indicatorView.autoresizingMask = NSViewMaxXMargin | NSViewMinXMargin | NSViewMaxYMargin | NSViewMinYMargin;
}
#endif

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunguarded-availability"
- (void)startAnimatingIndicator {
    self.indicatorView.hidden = NO;
#if TMSD_UIKIT
    if ([self.indicatorView respondsToSelector:@selector(observedProgress)] && self.indicatorView.observedProgress) {
        // Ignore NSProgress
    } else {
        self.indicatorView.progress = 0;
    }
#else
    self.indicatorView.indeterminate = YES;
    self.indicatorView.doubleValue = 0;
    [self.indicatorView startAnimation:nil];
#endif
}

- (void)stopAnimatingIndicator {
    self.indicatorView.hidden = YES;
#if TMSD_UIKIT
    if ([self.indicatorView respondsToSelector:@selector(observedProgress)] && self.indicatorView.observedProgress) {
        // Ignore NSProgress
    } else {
        self.indicatorView.progress = 1;
    }
#else
    self.indicatorView.indeterminate = NO;
    self.indicatorView.doubleValue = 100;
    [self.indicatorView stopAnimation:nil];
#endif
}

- (void)updateIndicatorProgress:(double)progress {
#if TMSD_UIKIT
    if ([self.indicatorView respondsToSelector:@selector(observedProgress)] && self.indicatorView.observedProgress) {
        // Ignore NSProgress
    } else {
        [self.indicatorView setProgress:progress animated:YES];
    }
#else
    self.indicatorView.indeterminate = progress > 0 ? NO : YES;
    self.indicatorView.doubleValue = progress * 100;
#endif
}
#pragma clang diagnostic pop

@end

@implementation TMSDWebImageProgressIndicator (TMSDConveniences)

+ (TMSDWebImageProgressIndicator *)defaultIndicator {
    TMSDWebImageProgressIndicator *indicator = [TMSDWebImageProgressIndicator new];
    return indicator;
}

#if TMSD_IOS
+ (TMSDWebImageProgressIndicator *)barIndicator {
    TMSDWebImageProgressIndicator *indicator = [TMSDWebImageProgressIndicator new];
    indicator.indicatorView.progressViewStyle = UIProgressViewStyleBar;
    return indicator;
}
#endif

@end

#endif
