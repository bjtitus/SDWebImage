/*
* This file is part of the TMSDWebImage package.
* (c) Olivier Poitrey <rs@dailymotion.com>
*
* For the full copyright and license information, please view the LICENSE
* file that was distributed with this source code.
*/

#import <TMSDWebImage/TMSDGraphicsImageRenderer.h>
#import <TMSDWebImage/TMSDImageGraphics.h>

@interface TMSDGraphicsImageRendererFormat ()
#if TMSD_UIKIT
@property (nonatomic, strong) UIGraphicsImageRendererFormat *uiformat API_AVAILABLE(ios(10.0), tvos(10.0));
#endif
@end

@implementation TMSDGraphicsImageRendererFormat
@synthesize scale = _scale;
@synthesize opaque = _opaque;
@synthesize preferredRange = _preferredRange;

#pragma mark - Property
- (CGFloat)scale {
#if TMSD_UIKIT
    if (@available(iOS 10.0, tvOS 10.10, *)) {
        return self.uiformat.scale;
    } else {
        return _scale;
    }
#else
    return _scale;
#endif
}

- (void)setScale:(CGFloat)scale {
#if TMSD_UIKIT
    if (@available(iOS 10.0, tvOS 10.10, *)) {
        self.uiformat.scale = scale;
    } else {
        _scale = scale;
    }
#else
    _scale = scale;
#endif
}

- (BOOL)opaque {
#if TMSD_UIKIT
    if (@available(iOS 10.0, tvOS 10.10, *)) {
        return self.uiformat.opaque;
    } else {
        return _opaque;
    }
#else
    return _opaque;
#endif
}

- (void)setOpaque:(BOOL)opaque {
#if TMSD_UIKIT
    if (@available(iOS 10.0, tvOS 10.10, *)) {
        self.uiformat.opaque = opaque;
    } else {
        _opaque = opaque;
    }
#else
    _opaque = opaque;
#endif
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
- (TMSDGraphicsImageRendererFormatRange)preferredRange {
#if TMSD_UIKIT
    if (@available(iOS 10.0, tvOS 10.10, *)) {
        if (@available(iOS 12.0, tvOS 12.0, *)) {
            return (TMSDGraphicsImageRendererFormatRange)self.uiformat.preferredRange;
        } else {
            BOOL prefersExtendedRange = self.uiformat.prefersExtendedRange;
            if (prefersExtendedRange) {
                return TMSDGraphicsImageRendererFormatRangeExtended;
            } else {
                return TMSDGraphicsImageRendererFormatRangeStandard;
            }
        }
    } else {
        return _preferredRange;
    }
#else
    return _preferredRange;
#endif
}

- (void)setPreferredRange:(TMSDGraphicsImageRendererFormatRange)preferredRange {
#if TMSD_UIKIT
    if (@available(iOS 10.0, tvOS 10.10, *)) {
        if (@available(iOS 12.0, tvOS 12.0, *)) {
            self.uiformat.preferredRange = (UIGraphicsImageRendererFormatRange)preferredRange;
        } else {
            switch (preferredRange) {
                case TMSDGraphicsImageRendererFormatRangeExtended:
                    self.uiformat.prefersExtendedRange = YES;
                    break;
                case TMSDGraphicsImageRendererFormatRangeStandard:
                    self.uiformat.prefersExtendedRange = NO;
                default:
                    // Automatic means default
                    break;
            }
        }
    } else {
        _preferredRange = preferredRange;
    }
#else
    _preferredRange = preferredRange;
#endif
}
#pragma clang diagnostic pop

- (instancetype)init {
    self = [super init];
    if (self) {
#if TMSD_UIKIT
        if (@available(iOS 10.0, tvOS 10.10, *)) {
            UIGraphicsImageRendererFormat *uiformat = [[UIGraphicsImageRendererFormat alloc] init];
            self.uiformat = uiformat;
        } else {
#endif
#if TMSD_WATCH
            CGFloat screenScale = [WKInterfaceDevice currentDevice].screenScale;
#elif TMSD_UIKIT
            CGFloat screenScale = [UIScreen mainScreen].scale;
#elif TMSD_MAC
            NSScreen *mainScreen = nil;
            if (@available(macOS 10.12, *)) {
                mainScreen = [NSScreen mainScreen];
            } else {
                mainScreen = [NSScreen screens].firstObject;
            }
            CGFloat screenScale = mainScreen.backingScaleFactor ?: 1.0f;
#endif
            self.scale = screenScale;
            self.opaque = NO;
            self.preferredRange = TMSDGraphicsImageRendererFormatRangeStandard;
#if TMSD_UIKIT
        }
#endif
    }
    return self;
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunguarded-availability"
- (instancetype)initForMainScreen {
    self = [super init];
    if (self) {
#if TMSD_UIKIT
        if (@available(iOS 10.0, tvOS 10.0, *)) {
            UIGraphicsImageRendererFormat *uiformat;
            // iOS 11.0.0 GM does have `preferredFormat`, but iOS 11 betas did not (argh!)
            if ([UIGraphicsImageRenderer respondsToSelector:@selector(preferredFormat)]) {
                uiformat = [UIGraphicsImageRendererFormat preferredFormat];
            } else {
                uiformat = [UIGraphicsImageRendererFormat defaultFormat];
            }
            self.uiformat = uiformat;
        } else {
#endif
#if TMSD_WATCH
            CGFloat screenScale = [WKInterfaceDevice currentDevice].screenScale;
#elif TMSD_UIKIT
            CGFloat screenScale = [UIScreen mainScreen].scale;
#elif TMSD_MAC
            NSScreen *mainScreen = nil;
            if (@available(macOS 10.12, *)) {
                mainScreen = [NSScreen mainScreen];
            } else {
                mainScreen = [NSScreen screens].firstObject;
            }
            CGFloat screenScale = mainScreen.backingScaleFactor ?: 1.0f;
#endif
            self.scale = screenScale;
            self.opaque = NO;
            self.preferredRange = TMSDGraphicsImageRendererFormatRangeStandard;
#if TMSD_UIKIT
        }
#endif
    }
    return self;
}
#pragma clang diagnostic pop

+ (instancetype)preferredFormat {
    TMSDGraphicsImageRendererFormat *format = [[TMSDGraphicsImageRendererFormat alloc] initForMainScreen];
    return format;
}

@end

@interface TMSDGraphicsImageRenderer ()
@property (nonatomic, assign) CGSize size;
@property (nonatomic, strong) TMSDGraphicsImageRendererFormat *format;
#if TMSD_UIKIT
@property (nonatomic, strong) UIGraphicsImageRenderer *uirenderer API_AVAILABLE(ios(10.0), tvos(10.0));
#endif
@end

@implementation TMSDGraphicsImageRenderer

- (instancetype)initWithSize:(CGSize)size {
    return [self initWithSize:size format:TMSDGraphicsImageRendererFormat.preferredFormat];
}

- (instancetype)initWithSize:(CGSize)size format:(TMSDGraphicsImageRendererFormat *)format {
    NSParameterAssert(format);
    self = [super init];
    if (self) {
        self.size = size;
        self.format = format;
#if TMSD_UIKIT
        if (@available(iOS 10.0, tvOS 10.0, *)) {
            UIGraphicsImageRendererFormat *uiformat = format.uiformat;
            self.uirenderer = [[UIGraphicsImageRenderer alloc] initWithSize:size format:uiformat];
        }
#endif
    }
    return self;
}

- (UIImage *)imageWithActions:(NS_NOESCAPE TMSDGraphicsImageDrawingActions)actions {
    NSParameterAssert(actions);
#if TMSD_UIKIT
    if (@available(iOS 10.0, tvOS 10.0, *)) {
        UIGraphicsImageDrawingActions uiactions = ^(UIGraphicsImageRendererContext *rendererContext) {
            if (actions) {
                actions(rendererContext.CGContext);
            }
        };
        return [self.uirenderer imageWithActions:uiactions];
    } else {
#endif
        TMSDGraphicsBeginImageContextWithOptions(self.size, self.format.opaque, self.format.scale);
        CGContextRef context = TMSDGraphicsGetCurrentContext();
        if (actions) {
            actions(context);
        }
        UIImage *image = TMSDGraphicsGetImageFromCurrentImageContext();
        TMSDGraphicsEndImageContext();
        return image;
#if TMSD_UIKIT
    }
#endif
}

@end
