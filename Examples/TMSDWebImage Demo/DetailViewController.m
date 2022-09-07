/*
 * This file is part of the TMSDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import <TMSDWebImage/DetailViewController.h>
#import <TMSDWebImage/TMSDWebImage.h>

@interface DetailViewController ()

@property (strong, nonatomic) IBOutlet TMSDAnimatedImageView *imageView;

@end

@implementation DetailViewController

- (void)configureView {
    if (!self.imageView.tmsd_imageIndicator) {
        self.imageView.tmsd_imageIndicator = TMSDWebImageProgressIndicator.defaultIndicator;
    }
    [self.imageView tmsd_setImageWithURL:self.imageURL
                      placeholderImage:nil
                               options:TMSDWebImageProgressiveLoad];
    self.imageView.shouldCustomLoopCount = YES;
    self.imageView.animationRepeatCount = 0;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self configureView];
    self.navigationItem.rightBarButtonItem = [UIBarButtonItem.alloc initWithTitle:@"Toggle Animation"
                                                                            style:UIBarButtonItemStylePlain
                                                                           target:self
                                                                           action:@selector(toggleAnimation:)];
}

- (void)toggleAnimation:(UIResponder *)sender {
    self.imageView.isAnimating ? [self.imageView stopAnimating] : [self.imageView startAnimating];
}

@end
