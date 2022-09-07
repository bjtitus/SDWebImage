/*
 * This file is part of the TMSDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import <TMSDWebImage/InterfaceController.h>
#import <TMSDWebImage/TMSDWebImage.h>

@interface InterfaceController()

@property (weak) IBOutlet WKInterfaceImage *staticImageInterface;
@property (weak) IBOutlet WKInterfaceImage *simpleAnimatedImageInterface;
@property (weak) IBOutlet WKInterfaceImage *animatedImageInterface;
@property (nonatomic, strong) TMSDAnimatedImagePlayer *player;

@end


@implementation InterfaceController

- (void)awakeWithContext:(id)context {
    [super awakeWithContext:context];

    // Configure interface objects here.
}

- (void)willActivate {
    // This method is called when watch view controller is about to be visible to user
    [super willActivate];
    
    [self addMenuItemWithItemIcon:WKMenuItemIconTrash title:@"Clear Cache" action:@selector(clearCache)];
    
    // Static image
    NSString *urlString1 = @"http://www.ioncannon.net/wp-content/uploads/2011/06/test2.webp";
    [self.staticImageInterface tmsd_setImageWithURL:[NSURL URLWithString:urlString1]];
    
    // Simple animated image playback
    NSString *urlString2 = @"http://apng.onevcat.com/assets/elephant.png";
    [self.simpleAnimatedImageInterface tmsd_setImageWithURL:[NSURL URLWithString:urlString2] completed:^(UIImage * _Nullable image, NSError * _Nullable error, TMSDImageCacheType cacheType, NSURL * _Nullable imageURL) {
        // `WKInterfaceImage` unlike `UIImageView`. Even the image is animated image, you should explicitly call `startAnimating` to play animation.
        [self.simpleAnimatedImageInterface startAnimating];
    }];
    
    // Complicated but the best performance animated image playback
    // If you use the above method to display this GIF (389 frames), Apple Watch will consume 800+MB and cause OOM
    // This is actualy the same backend like `TMSDAnimatedImageView` on iOS, recommend to use
    NSString *urlString3 = @"https://raw.githubusercontent.com/liyong03/YLGIFImage/master/YLGIFImageDemo/YLGIFImageDemo/joy.gif";
    [self.animatedImageInterface tmsd_setImageWithURL:[NSURL URLWithString:urlString3] placeholderImage:nil options:TMSDWebImageProgressiveLoad context:@{TMSDWebImageContextAnimatedImageClass : TMSDAnimatedImage.class} progress:nil completed:^(UIImage * _Nullable image, NSError * _Nullable error, TMSDImageCacheType cacheType, NSURL * _Nullable imageURL) {
        if (![image isKindOfClass:[TMSDAnimatedImage class]]) {
            return;
        }
        __weak typeof(self) wself = self;
        self.player = [TMSDAnimatedImagePlayer playerWithProvider:(TMSDAnimatedImage *)image];
        self.player.animationFrameHandler = ^(NSUInteger index, UIImage * _Nonnull frame) {
            [wself.animatedImageInterface setImage:frame];
        };
        [self.player startPlaying];
    }];
}

- (void)clearCache {
    [TMSDImageCache.sharedImageCache clearMemory];
    [TMSDImageCache.sharedImageCache clearDiskOnCompletion:nil];
}

- (void)didDeactivate {
    // This method is called when watch view controller is no longer visible
    [super didDeactivate];
}

@end



