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
@property (nonatomic, strong) NSArray *tags;
@property (nonatomic, strong) NSPersistentStore *cachePersistentStore;

@property (nonatomic, strong) UIAlertController *addTagAlertController;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
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
        NSLog(@"sourcesite -> %@ CPS %@",self.sourceSite, self.cachePersistentStore.URL);
        
    }
    
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
    
    [self setupTagsWithDefaultTag];
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
                               self.tags = [self getAllTags];
                               [self.tableView reloadData];
                           }];
    /*
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
     */
}


- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    [self.refreshControl endRefreshing];
    [self clearCachedMemoryImages];
    [self setupSourceSite];
    self.dataPreviewImageURLs = nil;
    self.navigationController.hidesBarsOnSwipe = NO;
    [self setupTagsWithDefaultTag];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
}

- (void)setupSourceSite {
    NSInteger sourceSiteType = [[NSUserDefaults standardUserDefaults] integerForKey:kSourceSite];
    if (IS_DEBUG_MODE) {
        NSLog(@"sourceSiteShort \n *** %li",(long)sourceSiteType);
    }

    switch (sourceSiteType) {
        case KonachanSourceSiteTypeUnseted:
            self.sourceSite = KONACHAN_SAFE_MODE_POST_LIMIT_PAGE_TAGS;
//            NSLog(@"default set to konachan.net");
            [[NSUserDefaults standardUserDefaults] setInteger:KonachanSourceSiteTypeKonachan_net
                                                       forKey:kSourceSite];
            if ([[NSUserDefaults standardUserDefaults] synchronize]) {
//                NSLog(@"default write source site to konachan.net");
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
        [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
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
        Tag *passTag;
        if ([sender isKindOfClass:[NSString class]]) {
            if ([sender isEqualToString:KonachanShortcutItemViewAll]) {
                NSEntityDescription *ed = [NSEntityDescription entityForName:@"Tag"
                                  inManagedObjectContext:self.managedObjectContext];
                passTag = (Tag *)[[NSManagedObject alloc] initWithEntity:ed
                                   insertIntoManagedObjectContext:nil];
                passTag.name = @"all";
            }
            if ([sender isEqualToString:KonachanShortcutItemViewLast]) {
                passTag = [self.tags lastObject];
            }
            if ([sender isEqualToString:KonachanShortcutItemViewSecond]) {
                passTag = [self.tags objectAtIndex:self.tags.count-2];
            }
        } else if ([sender isKindOfClass:[UITableViewCell class]]) {
            NSIndexPath *indexPath = [self.tableView indexPathForCell:sender];
            passTag = [self.tags objectAtIndex:indexPath.row];
        }
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
//             [self showHUDWithTitle:@"Error" content:@"Connection reset by peer. >_>"];
             [self.refreshControl endRefreshing];
         }];
}


- (IBAction)addTag:(id)sender {
    [self presentViewController:self.addTagAlertController animated:YES completion:nil];
}

- (NSArray *)getAllTags {
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Tag"];
    request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"createDate" ascending:YES]];
    return [self.managedObjectContext executeFetchRequest:request error:NULL];
}

#pragma mark - Lazy Initialization

- (NSArray *)tags {
    if (!_tags) {
        _tags = [self getAllTags];
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

- (NSPersistentStore *)cachePersistentStore {
    if (!_cachePersistentStore) {
        AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
        _cachePersistentStore = appDelegate.cachePersistentStore;
    }
    return _cachePersistentStore;
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

- (UIAlertController *)addTagAlertController {
    if (!_addTagAlertController) {
        __weak ViewController *weakSelf = self;
        _addTagAlertController = [UIAlertController alertControllerWithTitle:@"Add Tag"
                                                                     message:@""
                                                              preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *addAction = [UIAlertAction actionWithTitle:@"OK"
                                                            style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * _Nonnull action) {
                                                              UITextField *tagTextField =  _addTagAlertController.textFields[0];
                                                              NSString *addTagName = tagTextField.text;
                                                              NSArray *tagsArray = [addTagName componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                                                              NSString *tagName = [tagsArray componentsJoinedByString:@""];
                                                              if (![tagName isEqualToString:@""]) {
                                                                  Tag *newTag = [NSEntityDescription insertNewObjectForEntityForName:@"Tag"
                                                                                                              inManagedObjectContext:self.managedObjectContext];
                                                                  newTag.name = tagName;
                                                                  newTag.createDate = [NSDate new];
                                                                  self.tags = [self getAllTags];
                                                                  [self setupTagsWithDefaultTag];
                                                                  [self saveContext];
                                                              }
                                                              tagTextField.text = nil;
                                                          }];
        
        addAction.enabled = NO;
        
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel"
                                                               style:UIAlertActionStyleCancel
                                                             handler:^(UIAlertAction * _Nonnull action) {
                                                                 _addTagAlertController.textFields[0].text = nil;
                                                             }];
        
        [_addTagAlertController addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
            textField.placeholder = @"Input a tag keyword";
            NSNotificationCenter *notiCen = [NSNotificationCenter defaultCenter];
            [notiCen addObserverForName:UITextFieldTextDidChangeNotification
                                 object:textField
                                  queue:[NSOperationQueue mainQueue]
                             usingBlock:^(NSNotification * _Nonnull note) {
                                 if ([weakSelf isWhiteText:textField.text]) {
                                     addAction.enabled = NO;
                                 } else {
                                     addAction.enabled = YES;
                                 }
                             }];
            [notiCen addObserverForName:UITextFieldTextDidEndEditingNotification
                                 object:textField
                                  queue:[NSOperationQueue mainQueue]
                             usingBlock:^(NSNotification * _Nonnull note) {
                                 addAction.enabled = NO;
                             }];
        }];
        [_addTagAlertController addAction:addAction];
        [_addTagAlertController addAction:cancelAction];
    }
    return _addTagAlertController;
}

- (void)dealloc {
//    NSLog(@"dealloc");
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

- (BOOL)isWhiteText:(NSString *)text {
    NSArray *texts = [text componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSString *joinedtext = [texts componentsJoinedByString:@""];
    return joinedtext.length == 0 ? YES : NO;
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
