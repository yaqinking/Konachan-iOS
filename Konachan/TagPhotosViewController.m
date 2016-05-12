//
//  TagPhotosViewController.m
//  Konachan
//
//  Created by 小笠原やきん on 15/8/5.
//  Copyright © 2015年 yaqinking. All rights reserved.
//

#import "TagPhotosViewController.h"
#import "PhotoCell.h"
#import "KonachanTool.h"
#import "Tag+CoreDataProperties.h"
#import "Picture.h"
#import "MWPhotoBrowser.h"
#import "UIImageView+ProgressView.h"
#import "PreloadPhotoManager.h"
#import "Image.h"
#import "AppDelegate.h"

static NSString * const CellIdentifier = @"PhotoCell";

NSString * const TagAll = @"";

@interface TagPhotosViewController ()

@property (strong, nonatomic) NSMutableArray *photos;
@property (strong, nonatomic) NSMutableArray *previewPhotosURL;
@property (strong, nonatomic) NSMutableArray<NSString *> *cachedImageKeys;
@property (strong, nonatomic) MWPhotoBrowser *browser;

@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, strong) NSPersistentStore *cachePersistentStore;

@property (nonatomic, assign, getter=isEnterBrowser) BOOL enterBrowser;
@property (nonatomic, assign, getter=isLoadNextPage) BOOL loadNextPage;
@property (nonatomic, assign, getter=isLoadOriginal) BOOL loadOriginal;
@property (nonatomic, assign, getter=isOffline) BOOL offline;

@property (nonatomic, assign) NSInteger fetchAmount;
@property (nonatomic, assign) NSUInteger currentIndex;

@property (nonatomic, assign) CGFloat screenWidth;
@property (nonatomic, assign) CGFloat screenHeight;

@end

@implementation TagPhotosViewController

#pragma mark - Life cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    self.pageOffset = 1;
    self.loadNextPage = NO;
    self.currentIndex = 0;
    self.offline = YES;
    NSInteger thumbLoadWay = [[NSUserDefaults standardUserDefaults] integerForKey:kThumbLoadWay];
    self.loadOriginal = thumbLoadWay == KonachanPreviewImageLoadTypeLoadDownloaded ? YES : NO;
    NSLog(@"Offline %i", self.isOffline);
    if (self.isOffline) {
        [self setupOfflineDataWithTag:self.tag.name];
    } else {
        [self setupPhotosURLWithTag:self.tag.name andPageoffset:self.pageOffset];
    }
    [self setupCollectionViewLayout];
    CGRect screenBounds = [[UIScreen mainScreen] bounds];
    self.screenWidth = screenBounds.size.width;
    self.screenHeight = screenBounds.size.height;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    self.enterBrowser = NO;
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    NSLog(@"viewDidLayoutSubviews");
    if (self.enterBrowser) {
        [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:self.currentIndex inSection:0]
                                    atScrollPosition:UICollectionViewScrollPositionTop
                                            animated:NO];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    /*
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Image"];
    NSArray *fetchedResults = [self.managedObjectContext executeFetchRequest:request error:nil];
    NSLog(@"viewWillAppear Fetched Results %lu", (unsigned long)fetchedResults.count);
    
    NSString *frTitle = [NSString stringWithFormat:@"FR%lu", (unsigned long)fetchedResults.count];
    UIBarButtonItem *fr = [[UIBarButtonItem alloc] initWithTitle:frTitle
                                                           style:UIBarButtonItemStylePlain target:self action:@selector(showLocal:)];
    self.navigationItem.rightBarButtonItem = fr;
    
//    self.offline = [[NSUserDefaults standardUserDefaults] boolForKey:@"OfflineMode"];
    self.offline = YES;
     */
}

- (void)showLocal:(id)sender {
    NSLog(@"Local");
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    [appDelegate saveContext];
}

- (void)setupCollectionViewLayout {
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.minimumLineSpacing = 5;
    layout.minimumInteritemSpacing = 0;
    self.collectionView.collectionViewLayout = layout;
}

#pragma mark - Scroll view delegate

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView{
    if (!self.isOffline) {
        float endScrolling = scrollView.contentOffset.y + scrollView.frame.size.height;
        
        if (endScrolling >= scrollView.contentSize.height){
            if (self.isLoadNextPage) {
                NSLog(@"loadNextPageData......");
                [self setupPhotosURLWithTag:self.tag.name andPageoffset:self.pageOffset];
            }
        }
    }
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(nonnull UICollectionView *)collectionView {
    return 1;
}

- (nonnull UICollectionViewCell *)collectionView:(nonnull UICollectionView *)collectionView cellForItemAtIndexPath:(nonnull NSIndexPath *)indexPath {
    PhotoCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:CellIdentifier forIndexPath:indexPath];
    NSURL *photoURL = [self.previewPhotosURL objectAtIndex:indexPath.row];
    //use cachedKey to display photo
    /*
    NSString *cacheKey = photoURL.absoluteString;
    [cell.image setImage:[self cachedImageForKey:cacheKey]];
     */
//    if (self.isOffline) {
//        NSString *cacheKey = photoURL.absoluteString;
//        [cell.image setImage:[self cachedImageForKey:cacheKey]];
//    } else {
        [cell.image sd_setImageWithURL:photoURL completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
            if (error) {
                [cell.image setImage:[UIImage imageNamed:@"placeholder"]];
            }
        } usingProgressView:nil];
//    }
    return cell;
}

- (UIImage *)cachedImageForKey:(NSString *)cachedKey {
    return [[SDImageCache sharedImageCache] imageFromDiskCacheForKey:cachedKey];
}

- (NSInteger)collectionView:(nonnull UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.previewPhotosURL.count;
}


#pragma mark - UICollectionViewFlowLayout

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    if (self.isLoadOriginal) {
        if (iPadProLandscape || iPadProPortrait) {
            return CGSizeMake(675, 485);
        }
        if (iPad) {
            return CGSizeMake(505, 355);
        }
        if (iPhone6Portrait || iPhone6Landscape) {
            return CGSizeMake(325, 165);
        }
        if (iPhone6PlusPortrait || iPhone6PlusLandscape) {
            return CGSizeMake(362, 180);
        }
    } else {
        if (iPhone6Portrait || iPhone6Landscape) {
//            return CGSizeMake(375/3-5, 667/6);
            return CGSizeMake(120, 112);
        }
        if (iPhone6PlusPortrait || iPhone6PlusLandscape) {
//            return CGSizeMake(414/4-5, 736/8);
            return CGSizeMake(99, 92);
        }
    }
    return CGSizeMake(150, 150);
}

#pragma mark - UICollectionViewDelegate


- (void)collectionView:(nonnull UICollectionView *)collectionView didSelectItemAtIndexPath:(nonnull NSIndexPath *)indexPath {
    self.enterBrowser = YES;
    
    self.browser = [[MWPhotoBrowser alloc] initWithPhotos:self.photos];
    [self.browser setCurrentPhotoIndex:indexPath.row];
    self.browser.delegate = self;
    self.browser.enableGrid = NO;
    self.browser.displayNavArrows = YES;
    self.browser.zoomPhotosToFill = YES;
    self.browser.enableSwipeToDismiss = YES;
//    self.browser.automaticallyAdjustsScrollViewInsets = YES;
    [self.navigationController pushViewController:self.browser animated:YES];
}

- (BOOL)isCurrentLoadAllWithTag:(NSString *)tag {
    return ([tag isEqualToString:@"post"] || [tag isEqualToString:@"all"]) ? YES : NO;
}

#pragma mark - Load photos
- (void)setupOfflineDataWithTag:(NSString *)tag {
    NSLog(@"Offline mode");
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Image"];
    NSArray<Image *> *fetchedResults = [self.managedObjectContext executeFetchRequest:request error:nil];
    [fetchedResults enumerateObjectsUsingBlock:^(Image * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString *previewURLString = obj.preview_url;
        NSString *sampleURLString = obj.sample_url;
        NSString *fileURLString = obj.file_url;
        NSString *jpegURLString = obj.jpeg_url;
        NSString *picTitle = obj.tags;
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        NSInteger downloadImageType = [userDefaults integerForKey:kDownloadImageType];
        
        Picture *photoPic;
        switch (downloadImageType) {
            case KonachanImageDownloadTypeSample:
                photoPic = [[Picture alloc] initWithURL:[NSURL URLWithString:sampleURLString]];
                break;
            case KonachanImageDownloadTypeJPEG:
                photoPic = [[Picture alloc] initWithURL:[NSURL URLWithString:jpegURLString]];
                break;
            case KonachanImageDownloadTypeFile:
                photoPic = [[Picture alloc] initWithURL:[NSURL URLWithString:fileURLString]];
                break;
            default:
                photoPic = [[Picture alloc] initWithURL:[NSURL URLWithString:sampleURLString]];
                break;
        }
        [self.photos addObject:photoPic];
        photoPic.caption = picTitle;
        
        NSInteger thumbLoadWay = [[NSUserDefaults standardUserDefaults] integerForKey:kThumbLoadWay];
        
        switch (thumbLoadWay) {
            case KonachanPreviewImageLoadTypeLoadPreview:
                [self.previewPhotosURL addObject:[NSURL URLWithString:previewURLString]];
                
                break;
            case KonachanPreviewImageLoadTypeLoadDownloaded:
                switch (downloadImageType) {
                    case KonachanImageDownloadTypeSample:
                        [self.previewPhotosURL addObject:[NSURL URLWithString:sampleURLString]];
                        break;
                    case KonachanImageDownloadTypeJPEG:
                        [self.previewPhotosURL addObject:[NSURL URLWithString:jpegURLString]];
                        break;
                    case KonachanImageDownloadTypeFile:
                        [self.previewPhotosURL addObject:[NSURL URLWithString:fileURLString]];
                        break;
                    default:
                        break;
                }
                break;
            default:
                break;
        }
    }];
    self.navigationItem.title = [NSString stringWithFormat:@"Total %lu",(unsigned long)self.photos.count];
    [self.collectionView reloadData];
    [self.browser reloadData];
}
- (void)setupPhotosURLWithTag:(NSString *)tag andPageoffset:(int)pageOffset {
    MBProgressHUD *hud;
    if (!self.isLoadNextPage) {
        hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        hud.mode = MBProgressHUDModeIndeterminate;
        hud.labelText = @"Loading";
    }
    
    NSString *url;
    if ([self isCurrentLoadAllWithTag:tag]) {
        url = [NSString stringWithFormat:self.sourceSite, self.fetchAmount, pageOffset, TagAll];
    } else {
        url = [NSString stringWithFormat:self.sourceSite,self.fetchAmount,pageOffset,tag];
    }
    self.pageOffset ++;
    self.loadNextPage = NO;
    NSUInteger beforeReqPhotosCount = self.previewPhotosURL.count;
    
    if (IS_DEBUG_MODE) {
        NSLog(@"url %@",url);
    }
    
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    [manager GET:url
      parameters:nil
        progress:nil
         success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
             dispatch_async(dispatch_queue_create("data", nil), ^{
                 for (NSDictionary *picDict in responseObject) {
                     NSString *previewURLString = picDict[PreviewURL];
                     NSString *sampleURLString  = picDict[SampleURL];
                     NSString *jpegURLString = picDict[JPEGURL];
                     NSString *fileURLString = picDict[FileURL];
                     NSString *picTitle         = picDict[PictureTags];
                     NSString *md5 = picDict[@"md5"];
                     NSInteger create_at = [picDict[@"created_at"] integerValue];
                     NSInteger image_id = [picDict[@"id"] integerValue];
                     NSString *rating = picDict[@"rating"];
                     NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
                     NSInteger downloadImageType = [userDefaults integerForKey:kDownloadImageType];
                     
                     
                     NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Image"];
                     request.predicate = [NSPredicate predicateWithFormat:@"image_id == %i",image_id];
                     NSArray *fetchedImages = [self.managedObjectContext executeFetchRequest:request error:NULL];
                     NSLog(@"fetchedImages count %lu", (unsigned long)fetchedImages.count);
                     if (fetchedImages.count == 0) {
                         Image *image = [NSEntityDescription insertNewObjectForEntityForName:@"Image" inManagedObjectContext:self.managedObjectContext];
                         image.image_id = [NSNumber numberWithInteger:image_id];
                         image.create_at = [NSNumber numberWithInteger:create_at];
                         image.md5 = md5;
                         image.tags = picTitle;
                         image.preview_url = previewURLString;
                         image.sample_url = sampleURLString;
                         image.file_url = fileURLString;
                         image.jpeg_url = jpegURLString;
                         image.rating = rating;
                         [self.managedObjectContext assignObject:image toPersistentStore:self.cachePersistentStore];
                         NSLog(@"Not exist %@", image);
                     }
                     
                     Picture *photoPic;
                     switch (downloadImageType) {
                         case KonachanImageDownloadTypeSample:
                             photoPic = [[Picture alloc] initWithURL:[NSURL URLWithString:sampleURLString]];
                             break;
                         case KonachanImageDownloadTypeJPEG:
                             photoPic = [[Picture alloc] initWithURL:[NSURL URLWithString:jpegURLString]];
                             break;
                         case KonachanImageDownloadTypeFile:
                             photoPic = [[Picture alloc] initWithURL:[NSURL URLWithString:fileURLString]];
                             break;
                         default:
                             photoPic = [[Picture alloc] initWithURL:[NSURL URLWithString:sampleURLString]];
                             break;
                     }
                     [self.photos addObject:photoPic];
                     photoPic.caption = picTitle;
                     if (IS_DEBUG_MODE) {
                         //                    NSLog(@"Sample URL %@",sampleURLString);
                         //                    NSLog(@"Preview URL %@",previewURLString);
                     }
                     
                     NSInteger thumbLoadWay = [[NSUserDefaults standardUserDefaults] integerForKey:kThumbLoadWay];
                     
                     switch (thumbLoadWay) {
                         case KonachanPreviewImageLoadTypeLoadPreview:
                             [self.previewPhotosURL addObject:[NSURL URLWithString:previewURLString]];
                             
                             break;
                         case KonachanPreviewImageLoadTypeLoadDownloaded:
                             switch (downloadImageType) {
                                 case KonachanImageDownloadTypeSample:
                                     [self.previewPhotosURL addObject:[NSURL URLWithString:sampleURLString]];
                                     break;
                                 case KonachanImageDownloadTypeJPEG:
                                     [self.previewPhotosURL addObject:[NSURL URLWithString:jpegURLString]];
                                     break;
                                 case KonachanImageDownloadTypeFile:
                                     [self.previewPhotosURL addObject:[NSURL URLWithString:fileURLString]];
                                     break;
                                 default:
                                     break;
                             }
                             break;
                         default:
                             break;
                     }
                     
                 }
                 NSUInteger afterReqPhotosCount = self.previewPhotosURL.count;
                 self.loadNextPage = YES;
                 [self setupPreloadNextPageImagesWithTag:tag pageOffset:pageOffset];
                 dispatch_async(dispatch_get_main_queue(), ^{
                     [hud hide:YES];
                     if (afterReqPhotosCount == 0) {
                         NSLog(@"No images");
                         self.navigationItem.title = @"No images";
                         [self showHUDWithTitle:@"No images >_<" content:@""];
                         return ;
                     }
                     if (afterReqPhotosCount == beforeReqPhotosCount) {
                         [self showHUDWithTitle:@"No more images >_>" content:@""];
                     }
                     self.navigationItem.title = [NSString stringWithFormat:@"Total %lu",(unsigned long)self.photos.count];
                     [self.collectionView reloadData];
                     [self.browser reloadData];
                     if (IS_DEBUG_MODE) {
                         NSLog(@"count %lu",(unsigned long)self.previewPhotosURL.count);
                     }
                     
                 });
                 
             });
        } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
            NSLog(@"failure %@",error);
            [hud hide:YES];
            self.navigationItem.title = @"No images";
            [self showHUDWithTitle:@"Error" content:@"Connection reset by peer."];
            //由于在发送请求之前已经将 pageOffset + 1 ,这里需要 - 1 来保证过几秒之后加载的还是请求失败的页面，毕竟 API 短时间内使用次数有限……
            self.pageOffset --;
            self.loadNextPage = YES;
        }];
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

- (void)setupPreloadNextPageImagesWithTag:(NSString *)tag pageOffset:(NSInteger )pageOffset{
    BOOL isPreloadNextPageImages = [[NSUserDefaults standardUserDefaults] boolForKey:kPreloadNextPage];
    if (isPreloadNextPageImages) {
        if (pageOffset == 1) {
            NSString *firstPage;
            if ([self isCurrentLoadAllWithTag:tag]) {
                firstPage = [NSString stringWithFormat:self.sourceSite, self.fetchAmount, pageOffset, TagAll];
            } else {
                firstPage = [NSString stringWithFormat:self.sourceSite, self.fetchAmount, pageOffset, tag];
            }
            [[PreloadPhotoManager manager] GET:firstPage];
        }
        NSString *nextPage;
        if ([self isCurrentLoadAllWithTag:tag]) {
            nextPage = [NSString stringWithFormat:self.sourceSite, self.fetchAmount, pageOffset+1, TagAll];
        } else {
            nextPage = [NSString stringWithFormat:self.sourceSite, self.fetchAmount, pageOffset+1, tag];
        }
        [[PreloadPhotoManager manager] GET:nextPage];
    }
}

#pragma mark - UICollectionViewFlowLayoutDelegate

#pragma mark - MWPhotoBrowserDelegate

- (NSUInteger)numberOfPhotosInPhotoBrowser:(MWPhotoBrowser *)photoBrowser {
    return self.photos.count;
}

- (id <MWPhoto>)photoBrowser:(MWPhotoBrowser *)photoBrowser photoAtIndex:(NSUInteger)index {
    if (index < self.photos.count){
        return [self.photos objectAtIndex:index];
    }
    return nil;
}

- (void)photoBrowser:(MWPhotoBrowser *)photoBrowser didDisplayPhotoAtIndex:(NSUInteger)index {
    //Set current index in order to at viewDidLayoutSubviews scroll to item position;
    self.currentIndex = index;
    if (!self.isOffline) {
        if (index >= (self.photos.count - 6)) {
    //        NSLog(@"Load More");
            if (self.isLoadNextPage) {
    //            NSLog(@"Load More");
                [self setupPhotosURLWithTag:self.tag.name andPageoffset:self.pageOffset];
            }
        }
    }
}

#pragma mark - UIView

- (BOOL)prefersStatusBarHidden {
    return YES;
}

#pragma mark - Lazy Initialization

- (NSMutableArray *)photos {
    if (!_photos) {
        _photos = [[NSMutableArray alloc] init];
    }
    return _photos;
}

- (NSMutableArray<NSString *> *)cachedImageKeys {
    if (!_cachedImageKeys) {
        _cachedImageKeys = [[NSMutableArray alloc] init];
    }
    return _cachedImageKeys;
}

- (NSMutableArray *)previewPhotosURL {
    if (!_previewPhotosURL) {
        _previewPhotosURL = [[NSMutableArray alloc] init];
    }
    return _previewPhotosURL;
}

- (NSInteger)fetchAmount {
    return [[NSUserDefaults standardUserDefaults] integerForKey:kFetchAmount];
}

- (void)didReceiveMemoryWarning {
    [[SDImageCache sharedImageCache] clearMemory];
    [super didReceiveMemoryWarning];
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
@end
