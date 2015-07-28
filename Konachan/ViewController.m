//
//  ViewController.m
//  Konachan
//
//  Created by 小笠原やきん on 15/7/25.
//  Copyright © 2015年 yaqinking. All rights reserved.
//

#import "ViewController.h"
#import "SDImageCache.h"
#import "MWCommon.h"
#import "KonachanAPI.h"
#import "Tag.h"
#import <SDWebImage/UIImageView+WebCache.h>

#import "TagPhotoBrowserViewController.h"

@interface ViewController ()

@property (strong, nonatomic) Tag *currentTag;

@end

#define PAGE_LIMIT = 12

@implementation ViewController

- (nullable instancetype)initWithCoder:(nonnull NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        self.title = @"KonachanBrowser";
        [[SDImageCache sharedImageCache] cleanDisk];
        [[SDImageCache sharedImageCache] clearMemory];
        
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.tags = [[NSMutableArray alloc] init];
    self.manager = [AFHTTPRequestOperationManager manager];
    
    Tag *tag1 = [[Tag alloc] init];
    tag1.name = @"loli";
    
    [self.tags addObject:@"loli"];
    [self.tags addObject:@"pants"];
    //tag thumb image
    
    UINavigationBar *navBar = self.navigationController.navigationBar;
    navBar.tintColor = [UIColor whiteColor];
    navBar.barTintColor = nil;
    navBar.shadowImage = nil;
    navBar.translucent = YES;
    navBar.barStyle = UIBarStyleBlackTranslucent;
    [navBar setBackgroundImage:nil forBarMetrics:UIBarMetricsDefault];
//    [navBar setBackgroundImage:nil forBarMetrics:UIBarMetricsLandscapePhone];
    [navBar setBackgroundImage:nil forBarMetrics:UIBarMetricsCompact];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source
- (NSInteger)tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.tags.count;
}

- (UITableViewCell *)tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    NSString *TagCellIdentifier = @"TagCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:TagCellIdentifier];
    cell.textLabel.text = self.tags[indexPath.row];
    
    [cell.imageView sd_setImageWithURL:[NSURL URLWithString:@"http://konachan.com/data/preview/bd/e3/bde340076d768f2f1ecf0491a4dfccdc.jpg"] placeholderImage:[UIImage imageNamed:@"avatar-sqare.jpeg"]];
    return cell;
}

- (CGFloat)tableView:(nonnull UITableView *)tableView heightForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    return 50.0f;
}


- (void)prepareForSegue:(nonnull UIStoryboardSegue *)segue sender:(nullable id)sender {
    if ([segue.identifier isEqualToString:@"TagPics"]) {
        TagPhotoBrowserViewController *tgvc = [segue destinationViewController];

        NSLog(@"%@",sender);

    }
}



@end
