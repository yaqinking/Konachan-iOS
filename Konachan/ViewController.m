//
//  ViewController.m
//  Konachan
//
//  Created by 小笠原やきん on 15/7/25.
//  Copyright © 2015年 yaqinking. All rights reserved.
//

#import "ViewController.h"
#import "SDImageCache.h"
#import "KonachanAPI.h"
#import "Tag.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import "TagPhotoBrowserViewController.h"
#import "TagStore.h"

#import "TagTableViewCell.h"

@interface ViewController ()


@end

#define PAGE_LIMIT = 12

@implementation ViewController

- (nullable instancetype)initWithCoder:(nonnull NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        self.title = @"Konachan";
        [[SDImageCache sharedImageCache] cleanDisk];
        [[SDImageCache sharedImageCache] clearMemory];
        
    }
    return self;
}


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
//    self.tags = [[NSMutableArray alloc] init];
    self.manager = [AFHTTPRequestOperationManager manager];
    
    self.previewImageURLs = [[NSMutableArray alloc] init];
    
    
    UINavigationBar *navBar = self.navigationController.navigationBar;
    navBar.tintColor = [UIColor whiteColor];
    navBar.barTintColor = nil;
    navBar.shadowImage = nil;
    navBar.translucent = YES;
    navBar.barStyle = UIBarStyleBlackTranslucent;
    [navBar setBackgroundImage:nil forBarMetrics:UIBarMetricsDefault];
//    [navBar setBackgroundImage:nil forBarMetrics:UIBarMetricsLandscapePhone];
    [navBar setBackgroundImage:nil forBarMetrics:UIBarMetricsCompact];
    
    
    
    self.tags = [[TagStore sharedStore] allTags];
    
    [self setupTagsWithDefaultTag];
    
    CGFloat red = 33.0;
    CGFloat green = 33.0;
    CGFloat blue = 33.0;
    CGFloat alpha = 255.0;
    UIColor *color = [UIColor colorWithRed:(red/255.0) green:(green/255.0) blue:(blue/255.0) alpha:(alpha/255.0)];
    self.tableView.backgroundColor = color;
    
    [self.tableView setSeparatorColor:color];
    
    
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
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
    TagTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:TagCellIdentifier];
    Tag *tag = [self.tags objectAtIndex:indexPath.row];
    cell.tagTextLabel.text = tag.name;
//    cell.detailTextLabel.text = [NSString stringWithFormat:@"%d pictures",tag.cachedPicsCount];
    

//    [cell.imageView.image imageWithRenderingMode:UIImageRenderingModeAutomatic];
    if (self.previewImageURLs.count > 0 ) {
        [cell.tagImageView sd_setImageWithURL:[self.previewImageURLs objectAtIndex:indexPath.row] placeholderImage:[UIImage imageNamed:@"avatar-sqare.jpeg"]];
//        [cell.tagImageView sd_setImageWithURL:[self.previewImageURLs objectAtIndex:indexPath.row]];
    }
    return cell;
}

- (CGFloat)tableView:(nonnull UITableView *)tableView heightForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    return 60.0f;
}


- (void)prepareForSegue:(nonnull UIStoryboardSegue *)segue sender:(nullable id)sender {
    if ([segue.identifier isEqualToString:@"TagPics"]) {
        TagPhotoBrowserViewController *tgvc = [segue destinationViewController];
        Tag *passTag = [self.tags objectAtIndex:[self.tableView indexPathForSelectedRow].row];
        tgvc.tag = passTag;
//        NSLog(@"%@",sender);

    }
}

- (void)setupTagsWithDefaultTag {
    NSUInteger tagsCount = self.tags.count;
    NSString *strTagsCount = [NSString stringWithFormat:@"%lu",(unsigned long)tagsCount];
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat: KONACHAN_POST_LIMIT_PAGE_TAGS,strTagsCount,1,@""]];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    NSLog(@"url %@",url);
    AFHTTPRequestOperation *op = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    op.responseSerializer = [AFJSONResponseSerializer serializer];
    [op setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        
        for (NSDictionary *picDict in responseObject) {
            //                        NSLog(@" Dict -> %@",picDict);
            NSString *previewURLString = picDict[KONACHAN_DOWNLOAD_TYPE_PREVIEW];
            //            NSString *jpegURLString = picDict[KONACHAN_DOWNLOAD_TYPE_JPEG];
           
            [self.previewImageURLs addObject:previewURLString];
        }
        [self.tableView reloadData];
        NSLog(@"%lu picturesURL",(unsigned long)self.previewImageURLs.count);
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"failure %@",error);
    }];
    [[NSOperationQueue mainQueue] addOperation:op];
}


@end
