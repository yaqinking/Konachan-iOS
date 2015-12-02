//
//  ViewController.m
//  Konachan
//
//  Created by 小笠原やきん on 15/7/25.
//  Copyright © 2015年 yaqinking. All rights reserved.
//

#import "ViewController.h"
#import "TagPhotosViewController.h"
#import "KonachanAPI.h"
#import "Tag+CoreDataProperties.h"
#import "TagTableViewCell.h"
#import "AppDelegate.h"
#import "AFNetworking.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import "SVPullToRefresh.h"


@interface ViewController ()

@property (nonatomic, strong) NSMutableArray *dataPreviewImageURLs;

@property (nonatomic, strong) AppDelegate *appDelegate;
@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, strong) NSManagedObjectModel *managedObjectModel;

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
    
    
    
    //fix first row hide when pull to refresh stop
    if ([self respondsToSelector:@selector(automaticallyAdjustsScrollViewInsets)]) {
        self.automaticallyAdjustsScrollViewInsets = NO;
        
        UIEdgeInsets insets = self.tableView.contentInset;
        insets.top          = self.navigationController.navigationBar.bounds.size.height +
        [UIApplication sharedApplication].statusBarFrame.size.height;
        self.tableView.contentInset          = insets;
        self.tableView.scrollIndicatorInsets = insets;
    }
    
    __weak ViewController *weakSelf = self;
    [self.tableView addPullToRefreshWithActionHandler:^{
        [weakSelf setupTagsWithDefaultTag];
    }];
    
    self.tableView.pullToRefreshView.arrowColor = [UIColor whiteColor];
    self.tableView.pullToRefreshView.textColor  = [UIColor whiteColor];
    
}

- (instancetype)init {
    self = [super init];
    if (self) {
    }
    return self;
}

- (void)observeiCloudChanges {
    NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];
    [defaultCenter addObserverForName:NSPersistentStoreDidImportUbiquitousContentChangesNotification
                               object:self.managedObjectContext.persistentStoreCoordinator
                                queue:[NSOperationQueue mainQueue]
                           usingBlock:^(NSNotification * _Nonnull note) {
                               NSLog(@"------- \n NSPersistentStoreDidImportUbiquitousContentChangesNotification \n --- %@",[NSThread currentThread]);
                               self.tags = nil;
                               [self setupTagsWithDefaultTag];
                           }];
    
}


- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self setupSourceSite];
//    [self.tableView triggerPullToRefresh];

}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    NSLog(@"viewDidDisappear");

}

- (void)setupSourceSite {
    NSString *sourceSiteShort = [[NSUserDefaults standardUserDefaults] stringForKey:kSourceSite];
    if (IS_DEBUG_MODE) {
        NSLog(@"sourceSiteShort \n *** %@",sourceSiteShort);
    }

    if (sourceSiteShort == nil) {
        self.sourceSite = KONACHAN_SAFE_MODE_POST_LIMIT_PAGE_TAGS;
        NSLog(@"default set to konachan.net");
        [[NSUserDefaults standardUserDefaults] setValue:@"Konachan.net" forKey:kSourceSite];
        if ([[NSUserDefaults standardUserDefaults] synchronize]) {
            NSLog(@"default write source site to konachan.net");
        }
    } else if ([sourceSiteShort isEqualToString:kKonachanMain]) {
        self.sourceSite = KONACHAN_POST_LIMIT_PAGE_TAGS;
    } else if ([sourceSiteShort isEqualToString:kKonachanSafe]) {
        self.sourceSite = KONACHAN_SAFE_MODE_POST_LIMIT_PAGE_TAGS;
    } else if ([sourceSiteShort isEqualToString:kYandere]) {
        self.sourceSite = YANDERE_POST_LIMIT_PAGE_TAGS;
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
        
    }
}


#pragma mark - Setup

- (void)setupTagsWithDefaultTag {
    __weak ViewController *weakSelf = self;
    
    self.previewImageURLs = [[NSMutableArray alloc] initWithCapacity:self.tags.count];
    
    NSUInteger tagsCount   = self.tags.count;
    NSURL *url             = [NSURL URLWithString:[NSString stringWithFormat: self.sourceSite,tagsCount,1,@""]];
    NSURLRequest *request  = [NSURLRequest requestWithURL:url];
    if (IS_DEBUG_MODE) {
        NSLog(@"url %@",url);
    }
    AFHTTPRequestOperation *op = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    if (op) {
        op.responseSerializer = [AFJSONResponseSerializer serializer];
    } else {
        op.responseSerializer = [AFImageResponseSerializer serializer];
    }
    [op setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
       
        for (NSDictionary *picDict in responseObject) {
            NSString *previewURLString = picDict[KONACHAN_DOWNLOAD_TYPE_PREVIEW];
            [self.dataPreviewImageURLs addObject:previewURLString];
        }
        
        self.previewImageURLs = [self.dataPreviewImageURLs copy];
        
        [self.tableView reloadData];
        [weakSelf.tableView.pullToRefreshView stopAnimating];
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"failure %@",[error localizedDescription]);
        [self.tableView.pullToRefreshView stopAnimating];
        
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

- (AppDelegate *)appDelegate {
    if (!_appDelegate) {
        _appDelegate = [[UIApplication sharedApplication] delegate];
    }
    return _appDelegate;
}

- (NSManagedObjectContext *)managedObjectContext {
    if (!_managedObjectContext) {
        _managedObjectContext = self.appDelegate.managedObjectContext;
    }
    return _managedObjectContext;
}

- (NSManagedObjectModel *)managedObjectModel {
    if (!_managedObjectModel) {
        _managedObjectModel = self.appDelegate.managedObjectModel;
    }
    return _managedObjectModel;
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

@end
