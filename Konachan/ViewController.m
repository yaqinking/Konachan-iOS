//
//  ViewController.m
//  Konachan
//
//  Created by 小笠原やきん on 15/7/25.
//  Copyright © 2015年 yaqinking. All rights reserved.
//

#import "ViewController.h"
#import "TagPhotosViewController.h"
#import "KonachanTool.h"
#import "Tag+CoreDataProperties.h"
#import "TagTableViewCell.h"
#import "AppDelegate.h"

@interface ViewController ()

@property (nonatomic, strong) NSMutableArray *dataPreviewImageURLs;
@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, strong) NSMutableArray *tags;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    NSLog(@"viewDidLoad");
    [self observeiCloudChanges];
    UINavigationBar *navBar = self.navigationController.navigationBar;
    navBar.tintColor        = [UIColor whiteColor];
    navBar.barTintColor     = nil;
    navBar.shadowImage      = nil;
    navBar.translucent      = YES;
    navBar.barStyle         = UIBarStyleBlackTranslucent;

    [navBar setBackgroundImage:nil forBarMetrics:UIBarMetricsDefault];
    [navBar setBackgroundImage:nil forBarMetrics:UIBarMetricsCompact];
    
    [self setupSourceSite];
    
    self.navigationItem.title = @"Konachan";
    if (IS_DEBUG_MODE) {
        NSLog(@"sourcesite -> %@",self.sourceSite);
    }
    
    [self setupTagsWithDefaultTag];
    
    CGFloat red = 33.0;
    CGFloat green = 33.0;
    CGFloat blue = 33.0;
    CGFloat alpha = 255.0;
    UIColor *color = [UIColor colorWithRed:(red/255.0) green:(green/255.0) blue:(blue/255.0) alpha:(alpha/255.0)];
    
    self.tableView.backgroundColor = color;
    self.tableView.separatorColor  = color;
    
    //Refresh Control
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self
                            action:@selector(refreshTags:)
                  forControlEvents:UIControlEventValueChanged];
    
//    NSLog(@"before 5s");
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//            NSLog(@"5s reload data");
            self.tags = nil;
            [self.tableView reloadData];
        });

}

- (void)refreshTags:(id)sender {
    [self setupTagsWithDefaultTag];
}

- (void)observeiCloudChanges {
    NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];
    [defaultCenter addObserverForName:NSPersistentStoreDidImportUbiquitousContentChangesNotification
                               object:self.managedObjectContext.persistentStoreCoordinator
                                queue:[NSOperationQueue mainQueue]
                           usingBlock:^(NSNotification * _Nonnull note) {
                               [self.managedObjectContext mergeChangesFromContextDidSaveNotification:note];
                               self.tags = nil;
                               [self.tableView reloadData];
                           }];
    [defaultCenter addObserverForName:NSPersistentStoreCoordinatorStoresWillChangeNotification
                               object:self.managedObjectContext
                                queue:[NSOperationQueue mainQueue]
                           usingBlock:^(NSNotification * _Nonnull note) {
                               NSLog(@"NSPersistentStoreCoordinatorStoresWillChangeNotification");
                           }];
    [defaultCenter addObserverForName:NSPersistentStoreCoordinatorWillRemoveStoreNotification
                               object:self.managedObjectContext
                                queue:[NSOperationQueue mainQueue]
                           usingBlock:^(NSNotification * _Nonnull note) {
                               NSLog(@"NSPersistentStoreCoordinatorWillRemoveStoreNotification");
                           }];
}


- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self clearCachedMemoryImages];
    [self setupSourceSite];
    self.dataPreviewImageURLs = nil;
    [self setupTagsWithDefaultTag];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
}

- (void)setupSourceSite {
    NSInteger sourceSiteType = [[NSUserDefaults standardUserDefaults] integerForKey:kSourceSite];
    if (IS_DEBUG_MODE) {
        NSLog(@"sourceSiteShort \n *** %i",sourceSiteType);
    }

    switch (sourceSiteType) {
        case KonachanSourceSiteTypeUnseted:
            self.sourceSite = KONACHAN_SAFE_MODE_POST_LIMIT_PAGE_TAGS;
            NSLog(@"default set to konachan.net");
            [[NSUserDefaults standardUserDefaults] setInteger:KonachanSourceSiteTypeKonachan_net
                                                       forKey:kSourceSite];
            if ([[NSUserDefaults standardUserDefaults] synchronize]) {
                NSLog(@"default write source site to konachan.net");
            }
            break;
        case KonachanSourceSiteTypeKonachan_com:
            self.sourceSite = KONACHAN_POST_LIMIT_PAGE_TAGS;
            break;
        case KonachanSourceSiteTypeKonachan_net:
            self.sourceSite = KONACHAN_SAFE_MODE_POST_LIMIT_PAGE_TAGS;
            break;
        case KonachanSourceSiteTypeYande_re:
            self.sourceSite = YANDERE_POST_LIMIT_PAGE_TAGS;
            break;
        default:
            break;
    }
}

#pragma mark - Table view data source
- (NSInteger)tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.tags.count;
}

- (UITableViewCell *)tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    NSString *TagCellIdentifier = @"TagCell";
    TagTableViewCell *cell      = [tableView dequeueReusableCellWithIdentifier:TagCellIdentifier];
    Tag *tag                    = [self.tags objectAtIndex:indexPath.row];
    cell.tagTextLabel.text      = tag.name;
    //    cell.detailTextLabel.text = [NSString stringWithFormat:@"%d pictures",tag.cachedPicsCount];
    
    if (self.previewImageURLs.count > 0 ) {
        [cell.tagImageView sd_setImageWithURL:[self.previewImageURLs objectAtIndex:indexPath.row] placeholderImage:[UIImage imageNamed:@"placeholder.jpg"]];
    }
    return cell;
}

#pragma mark - TabeleView Delegate

- (CGFloat)tableView:(nonnull UITableView *)tableView heightForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    return 70.0f;
}

- (void)tableView:(nonnull UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        Tag *tag      = self.tags[indexPath.row];
        [self.managedObjectContext deleteObject:tag];
        [self saveContext];
        self.tags = nil;
        [self setupTagsWithDefaultTag];
    }
}

- (void)saveContext {
    NSError *error = nil;
    if ([self.managedObjectContext hasChanges] && ![self.managedObjectContext save:&error]) {
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
    }
    
}

- (void)prepareForSegue:(nonnull UIStoryboardSegue *)segue sender:(nullable id)sender {
    if ([segue.identifier isEqualToString:@"Show Tag Photos"]) {
        TagPhotosViewController *tpvc = [segue destinationViewController];
        Tag *passTag = [self.tags objectAtIndex:[self.tableView indexPathForSelectedRow].row];
        tpvc.tag = passTag;
        tpvc.sourceSite = self.sourceSite;
    }
}


#pragma mark - Setup

- (void)setupTagsWithDefaultTag {
    NSUInteger tagsCount   = self.tags.count;
    NSURL *url             = [NSURL URLWithString:[NSString stringWithFormat: self.sourceSite,tagsCount,1,@""]];
    if (IS_DEBUG_MODE) {
        NSLog(@"url %@",url);
    }
    self.dataPreviewImageURLs = nil;
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    [manager GET:url.absoluteString
      parameters:nil progress:nil
         success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
             for (NSDictionary *picDict in responseObject) {
                 NSString *previewURLString = picDict[PreviewURL];
                 [self.dataPreviewImageURLs addObject:previewURLString];
             }
             
             self.previewImageURLs = [self.dataPreviewImageURLs copy];
             
             [self.tableView reloadData];
             [self.refreshControl endRefreshing];
         } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
             NSLog(@"failure %@",[error localizedDescription]);
             [self showHUDWithTitle:@"Error" content:@"Connection reset by peer. >_>"];
             [self.refreshControl endRefreshing];
         }];
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
                  if (IS_DEBUG_MODE) {
                      NSLog(@"%@",addTagName);
                  }
                  
                  Tag *newTag = [NSEntityDescription insertNewObjectForEntityForName:@"Tag"
                                                              inManagedObjectContext:self.managedObjectContext];
                  newTag.name = addTagName;
                  [self saveContext];
                  self.tags = nil;
                  [self setupTagsWithDefaultTag];
                  
              }
          }];
    
    addAction.enabled = NO;
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel"
                                                           style:UIAlertActionStyleCancel
                                                         handler:^(UIAlertAction * _Nonnull action) {

                                                         }];
    
    [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = @"Input a tag keyword";
        
        NSNotificationCenter *notiCen = [NSNotificationCenter defaultCenter];
        [notiCen addObserverForName:UITextFieldTextDidChangeNotification
                             object:textField
                              queue:[NSOperationQueue mainQueue]
                         usingBlock:^(NSNotification * _Nonnull note) {
                             addAction.enabled = YES;
                         }];
        
    }];
    
    [alert addAction:addAction];
    [alert addAction:cancelAction];
    
    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - Lazy Initialization

- (NSMutableArray *)tags {
    if (!_tags) {
        _tags = [[NSMutableArray alloc] init];
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Tag"];
        _tags = [[self.managedObjectContext executeFetchRequest:request
                                                 error:NULL] mutableCopy];
    }
    return _tags;
}

- (NSManagedObjectContext *)managedObjectContext {
    if (!_managedObjectContext) {
        AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
        _managedObjectContext = appDelegate.managedObjectContext;
    }
    return _managedObjectContext;
}

- (NSMutableArray *)dataPreviewImageURLs {
    if (!_dataPreviewImageURLs) {
        _dataPreviewImageURLs = [[NSMutableArray alloc] init];
    }
    return _dataPreviewImageURLs;
}

- (NSArray *)previewImageURLs {
    if (!_previewImageURLs) {
        _previewImageURLs = [[NSArray alloc] init];
    }
    return _previewImageURLs;
}

- (void)dealloc {
    NSLog(@"dealloc");
    NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];
    [defaultCenter removeObserver:self
                             name:NSPersistentStoreDidImportUbiquitousContentChangesNotification
                           object:self.managedObjectContext];
    
}

#pragma mark - Util

- (void) showHUDWithTitle:(NSString *)title content:(NSString *)content {
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.labelText = title;
    hud.detailsLabelText = content;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 3 * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [MBProgressHUD hideHUDForView:self.view animated:YES];
    });
}

#pragma mark - Memory

- (void)didReceiveMemoryWarning {
    [self clearCachedMemoryImages];
    [super didReceiveMemoryWarning];
}

- (void)clearCachedMemoryImages {
    [[SDImageCache sharedImageCache] clearMemory];
}

@end
