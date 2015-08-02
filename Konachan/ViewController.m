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

@property (nonatomic) BOOL isValidTag;

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
    
    UINavigationBar *navBar = self.navigationController.navigationBar;
    navBar.tintColor = [UIColor whiteColor];
    navBar.barTintColor = nil;
    navBar.shadowImage = nil;
    navBar.translucent = YES;
    navBar.barStyle = UIBarStyleBlackTranslucent;
    [navBar setBackgroundImage:nil forBarMetrics:UIBarMetricsDefault];
    [navBar setBackgroundImage:nil forBarMetrics:UIBarMetricsCompact];
    
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
    return [[[TagStore sharedStore] allTags] count];
}

- (UITableViewCell *)tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    NSString *TagCellIdentifier = @"TagCell";
    TagTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:TagCellIdentifier];
    Tag *tag = [[[TagStore sharedStore] allTags] objectAtIndex:indexPath.row];
    cell.tagTextLabel.text = tag.name;
//    cell.detailTextLabel.text = [NSString stringWithFormat:@"%d pictures",tag.cachedPicsCount];

    if (self.previewImageURLs.count > 0 ) {
        [cell.tagImageView sd_setImageWithURL:[self.previewImageURLs objectAtIndex:indexPath.row] placeholderImage:[UIImage imageNamed:@"avatar-sqare.jpeg"]];
    }
    return cell;
}

#pragma mark - TabeleView Delegate

- (CGFloat)tableView:(nonnull UITableView *)tableView heightForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    return 70.0f;
}


- (void)prepareForSegue:(nonnull UIStoryboardSegue *)segue sender:(nullable id)sender {
    if ([segue.identifier isEqualToString:@"TagPics"]) {
        TagPhotoBrowserViewController *tgvc = [segue destinationViewController];
        Tag *passTag = [[[TagStore sharedStore] allTags] objectAtIndex:[self.tableView indexPathForSelectedRow].row];
        tgvc.tag = passTag;
//        NSLog(@"%@",sender);

    }
}

#pragma mark - Setup

- (void)setupTagsWithDefaultTag {
   
    self.previewImageURLs = [[NSMutableArray alloc] initWithCapacity:[[[TagStore sharedStore] allTags] count]];
    
    NSUInteger tagsCount = [[[TagStore sharedStore] allTags] count];
    NSString *strTagsCount = [NSString stringWithFormat:@"%lu",(unsigned long)tagsCount];
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat: KONACHAN_POST_LIMIT_PAGE_TAGS,strTagsCount,1,@""]];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    NSLog(@"url %@",url);
    AFHTTPRequestOperation *op = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    op.responseSerializer = [AFJSONResponseSerializer serializer];
    [op setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        

//        if ([responseObject count] == 0) {
//            self.isValidTag = NO;
//            NSLog(@"Not valid tag");
//            return ;
//        } else {
//            NSLog(@"valid tag");
//        }
        
        for (NSDictionary *picDict in responseObject) {
            //                        NSLog(@" Dict -> %@",picDict);
            NSString *previewURLString = picDict[KONACHAN_DOWNLOAD_TYPE_PREVIEW];
            //            NSString *jpegURLString = picDict[KONACHAN_DOWNLOAD_TYPE_JPEG];
           
            [self.previewImageURLs addObject:previewURLString];
        }
        [self.tableView reloadData];
//        NSLog(@"%lu picturesURL",(unsigned long)self.previewImageURLs.count);
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"failure %@",error);
    }];
    [[NSOperationQueue mainQueue] addOperation:op];
}



- (IBAction)addTag:(id)sender {
    NSLog(@"addTag");
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Add Tag"
                                                                   message:@""
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *addAction = [UIAlertAction actionWithTitle:@"OK"
                                                        style:UIAlertActionStyleDefault
                                                      handler:^(UIAlertAction * _Nonnull action) {
                                         
                                                          UITextField *tagTextField =  alert.textFields[0];
                                                          if (![tagTextField.text isEqualToString:@""]) {
                                                              NSString *addTagName = tagTextField.text;
                                                              NSLog(@"%@",addTagName);
                                                              
                                                              Tag *newTag = [[TagStore sharedStore] createTag];
                                                              newTag.name = addTagName;
                                                              
                                                              NSInteger lastRow = [[[TagStore sharedStore] allTags] indexOfObject:newTag];
                                                              NSIndexPath *indexPath = [NSIndexPath indexPathForRow:lastRow inSection:0];
                                                              
                                                              [self setupTagsWithDefaultTag];
                                                              
                                                              [self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationTop];
                                                              
                                                          }
                                                      }];

    addAction.enabled = NO;
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel"
                                                        style:UIAlertActionStyleCancel
                                                      handler:^(UIAlertAction * _Nonnull action) {
                                                          NSLog(@"Cancel");
                                                      }];
    
    [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = @"Input a tag keyword";
        
        NSNotificationCenter *notiCen = [NSNotificationCenter defaultCenter];
        [notiCen addObserverForName:UITextFieldTextDidChangeNotification
                             object:textField queue:[NSOperationQueue mainQueue]
                         usingBlock:^(NSNotification * _Nonnull note) {
                             addAction.enabled = YES;
        }];
        
        
    }];
    
    [alert addAction:addAction];
    [alert addAction:cancelAction];
    
    [self presentViewController:alert animated:YES completion:nil];
}
@end
