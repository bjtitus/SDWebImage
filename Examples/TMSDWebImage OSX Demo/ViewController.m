/*
 * This file is part of the TMSDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import <TMSDWebImage/ViewController.h>
#import <TMSDWebImage/TMSDWebImage.h>

@interface ViewController ()

@property (weak) IBOutlet NSImageView *imageView1;
@property (weak) IBOutlet NSImageView *imageView2;
@property (weak) IBOutlet TMSDAnimatedImageView *imageView3;
@property (weak) IBOutlet TMSDAnimatedImageView *imageView4;
@property (weak) IBOutlet NSButton *clearCacheButton;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // For animated GIF rendering, set `animates` to YES or will only show the first frame
    self.imageView2.animates = YES; // `TMSDAnimatedImageRep` can be used for built-in `NSImageView` to support better GIF & APNG rendering as well. No need `TMSDAnimatedImageView`
    self.imageView4.animates = YES;
    
    // NSImageView + Static Image
    self.imageView1.tmsd_imageIndicator = TMSDWebImageProgressIndicator.defaultIndicator;
    [self.imageView1 tmsd_setImageWithURL:[NSURL URLWithString:@"https://raw.githubusercontent.com/recurser/exif-orientation-examples/master/Landscape_2.jpg"] placeholderImage:nil options:TMSDWebImageProgressiveLoad];
    
    // NSImageView + Animated Image
    self.imageView2.tmsd_imageIndicator = TMSDWebImageActivityIndicator.largeIndicator;
    [self.imageView2 tmsd_setImageWithURL:[NSURL URLWithString:@"https://raw.githubusercontent.com/onevcat/APNGKit/2.2.0/Tests/APNGKitTests/Resources/General/APNG-cube.apng"]];
    NSMenu *menu1 = [[NSMenu alloc] initWithTitle:@"Toggle Animation"];
    NSMenuItem *item1 = [menu1 addItemWithTitle:@"Toggle Animation" action:@selector(toggleAnimation:) keyEquivalent:@""];
    item1.tag = 1;
    self.imageView2.menu = menu1;
    
    // TMSDAnimatedImageView + Static Image
    [self.imageView3 tmsd_setImageWithURL:[NSURL URLWithString:@"https://nr-platform.s3.amazonaws.com/uploads/platform/published_extension/branding_icon/275/AmazonS3.png"]];
    
    // TMSDAnimatedImageView + Animated Image
    self.imageView4.tmsd_imageTransition = TMSDWebImageTransition.fadeTransition;
    self.imageView4.imageScaling = NSImageScaleProportionallyUpOrDown;
    self.imageView4.imageAlignment = NSImageAlignLeft; // supports NSImageView's layout properties
    [self.imageView4 tmsd_setImageWithURL:[NSURL URLWithString:@"http://littlesvr.ca/apng/images/SteamEngine.webp"]];
    NSMenu *menu2 = [[NSMenu alloc] initWithTitle:@"Toggle Animation"];
    NSMenuItem *item2 = [menu2 addItemWithTitle:@"Toggle Animation" action:@selector(toggleAnimation:) keyEquivalent:@""];
    item2.tag = 2;
    self.imageView4.menu = menu2;
    
    self.clearCacheButton.target = self;
    self.clearCacheButton.action = @selector(clearCacheButtonClicked:);
    [self.clearCacheButton tmsd_setImageWithURL:[NSURL URLWithString:@"https://png.icons8.com/color/100/000000/delete-sign.png"]];
    [self.clearCacheButton tmsd_setAlternateImageWithURL:[NSURL URLWithString:@"https://png.icons8.com/color/100/000000/checkmark.png"]];
}

- (void)clearCacheButtonClicked:(NSResponder *)sender {
    NSButton *button = (NSButton *)sender;
    button.state = NSControlStateValueOn;
    [[TMSDImageCache sharedImageCache] clearMemory];
    [[TMSDImageCache sharedImageCache] clearDiskOnCompletion:^{
        button.state = NSControlStateValueOff;
    }];
}

- (void)toggleAnimation:(NSMenuItem *)sender {
    NSImageView *imageView = sender.tag == 1 ? self.imageView2 : self.imageView4;
    if (imageView.animates) {
        imageView.animates = NO;
    } else {
        imageView.animates = YES;
    }
}

- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];

    // Update the view, if already loaded.
}

@end
