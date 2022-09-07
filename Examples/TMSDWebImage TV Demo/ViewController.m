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

@property (weak, nonatomic) IBOutlet UIImageView *imageView1;
@property (weak, nonatomic) IBOutlet UIImageView *imageView2;
@property (weak, nonatomic) IBOutlet TMSDAnimatedImageView *imageView3;
@property (weak, nonatomic) IBOutlet TMSDAnimatedImageView *imageView4;

@end


@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    [self.imageView1 tmsd_setImageWithURL:[NSURL URLWithString:@"https://nokiatech.github.io/heif/content/images/ski_jump_1440x960.heic"]];
    [self.imageView2 tmsd_setImageWithURL:[NSURL URLWithString:@"http://www.ioncannon.net/wp-content/uploads/2011/06/test2.webp"]];
    [self.imageView3 tmsd_setImageWithURL:[NSURL URLWithString:@"https://raw.githubusercontent.com/liyong03/YLGIFImage/master/YLGIFImageDemo/YLGIFImageDemo/joy.gif"]];
    [self.imageView4 tmsd_setImageWithURL:[NSURL URLWithString:@"http://littlesvr.ca/apng/images/SteamEngine.webp"]];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
