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
#import "LocalImageDataSource.h"
#import "AppDelegate.h"
#import <sys/utsname.h>
static NSString * const CellIdentifier = @"PhotoCell";

NSString * const TagAll = @"";

@interface TagPhotosViewController ()

@property (strong, nonatomic) NSMutableArray *photos;
@property (strong, nonatomic) NSMutableArray *previewPhotosURL;
@property (strong, nonatomic) MWPhotoBrowser *browser;

@property (nonatomic, assign, getter=isEnterBrowser) BOOL enterBrowser;
@property (nonatomic, assign, getter=isLoadNextPage) BOOL loadNextPage;
@property (nonatomic, assign, getter=isLoadOriginal) BOOL loadOriginal;
@property (nonatomic, assign, getter=isOffline) BOOL offline;

@property (nonatomic, assign) NSInteger fetchAmount;
@property (nonatomic, assign) NSUInteger currentIndex;

@property (nonatomic, assign) CGFloat screenWidth;
@property (nonatomic, assign) CGFloat screenHeight;

@property (nonatomic, strong) NSString *downloadImageTypeKey;

@end

@implementation TagPhotosViewController

#pragma mark - Life cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    self.pageOffset = 1;
    self.loadNextPage = NO;
    self.currentIndex = 0;
    NSInteger thumbLoadWay = [[NSUserDefaults standardUserDefaults] integerForKey:kThumbLoadWay];
    self.loadOriginal = thumbLoadWay == KonachanPreviewImageLoadTypeLoadDownloaded ? YES : NO;
    self.offline = [[NSUserDefaults standardUserDefaults] boolForKey:kOfflineMode];
    if (self.isOffline) {
        [self setupOfflineDataWithTag:self.tag.name];
    } else {
        [self setupPhotosURLWithTag:self.tag.name andPageoffset:self.pageOffset];
    }
    [self setupCollectionViewLayout];
    [self observeNotifications];
    [self setupGestures];
    [[SDImageCache sharedImageCache] setMaxMemoryCost:[self deviceMaxMemoryCost]];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    self.enterBrowser = NO;
    self.navigationController.hidesBarsOnSwipe = YES;
}

- (NSInteger)deviceMaxMemoryCost {
    unsigned long long physicalMemory = [NSProcessInfo processInfo].physicalMemory;
    NSInteger allowedMaxMemory = physicalMemory*0.5/4;
    return allowedMaxMemory;
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    if (self.enterBrowser) {
        [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:self.currentIndex inSection:0]
                                    atScrollPosition:UICollectionViewScrollPositionTop
                                            animated:NO];
    }
}

- (void)setupCollectionViewLayout {
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.minimumLineSpacing = 1;
    layout.minimumInteritemSpacing = 0;
    self.collectionView.collectionViewLayout = layout;
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    if (self.isEnterBrowser) {
        self.navigationController.hidesBarsOnSwipe = NO;
    }
    self.navigationItem.rightBarButtonItem = nil;
}

#pragma mark - Scroll view delegate

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView{
    if (!self.isOffline) {
        float endScrolling = scrollView.contentOffset.y + scrollView.frame.size.height;
        if (endScrolling >= scrollView.contentSize.height){
            if (self.isLoadNextPage) {
//                NSLog(@"loadNextPageData......");
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
    [cell.image sd_setImageWithURL:photoURL usingProgressView:nil];
    return cell;
}

- (NSInteger)collectionView:(nonnull UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.previewPhotosURL.count;
}

#pragma mark - Rotate

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    [self.collectionView.collectionViewLayout invalidateLayout];
}

#pragma mark - UICollectionViewFlowLayout

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return [self calculateCollectionViewItemSize];
}

- (CGSize )calculateCollectionViewItemSize {
    CGRect screenBounds = [[UIScreen mainScreen] bounds];
    self.screenWidth = screenBounds.size.width;
    self.screenHeight = screenBounds.size.height;

    NSInteger itemSpacing = 1;
    NSInteger heightItemCount = 1;
    NSInteger widthItemCount = 1;
    CGFloat contentWidth;
    CGFloat contentHeight;
    if (self.isLoadOriginal) {
        if (iPadProPortrait) {
            widthItemCount = 2;
            heightItemCount = 4;
        } else if (iPhone6Portrait || iPhone6PlusPortrait || iPhone4InchPortrait) {
            heightItemCount = 3;
        } else if (iPadProLandscape || iPadLandscape || iPhone6Landscape ||
                   iPhone6PlusLandscape || iPhone4InchLandscape || iPhone3_5InchLandscape) {
            widthItemCount = 2;
            heightItemCount = 2;
        } else if (iPadPortrait) {
            heightItemCount = 2;
        } else if (iPhone3_5InchPortrait) {
            heightItemCount = 2;
        } else {
            //Unknown device
            widthItemCount = 2;
            heightItemCount = 2;
        }
    } else {
        if (iPadProPortrait) {
            widthItemCount = 5;
            heightItemCount = 7;
        } else if (iPadProLandscape){
            widthItemCount = 6;
            heightItemCount = 5;
        } else if (iPadPortrait) {
            widthItemCount = 4;
            heightItemCount = 5;
        } else if (iPadLandscape) {
            widthItemCount = 5;
            heightItemCount = 4;
        } else if (iPhone6Portrait || iPhone6PlusPortrait || iPhone4InchPortrait) {
            widthItemCount = 2;
            heightItemCount = 4;
        } else if (iPhone6Landscape || iPhone6PlusLandscape || iPhone4InchLandscape) {
            widthItemCount = 4;
            heightItemCount = 2;
        } else if (iPhone3_5InchPortrait) {
            widthItemCount = 2;
            heightItemCount = 3;
        } else if (iPhone3_5InchLandscape) {
            widthItemCount = 3;
            heightItemCount = 2;
        } else {
            //Unknown device
            widthItemCount = 3;
            heightItemCount = 5;
        }
    }
    //ContentWidth need minus items spacing
    contentWidth = self.screenWidth - (widthItemCount > 2 ? ((widthItemCount - 1) * itemSpacing) : 1);
    //ContentHeight need minus navBarHeight and items spacing
    contentHeight = self.screenHeight - (heightItemCount > 2 ? ((heightItemCount - 1) * itemSpacing) : 1);
    return CGSizeMake(contentWidth / widthItemCount, contentHeight / heightItemCount);
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
    LocalImageDataSource *dataSource = [[LocalImageDataSource alloc] init];
    NSDictionary *imageDataDictionry = [dataSource imageDataDictionaryWithTag:tag];
    [self.previewPhotosURL addObjectsFromArray:imageDataDictionry[@"preview_urls"]];
    [self.photos addObjectsFromArray:imageDataDictionry[@"photos"]];
    self.navigationItem.title = [NSString stringWithFormat:@"Offline Total %lu",(unsigned long)self.photos.count];
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
    
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    [manager GET:url
      parameters:nil
        progress:nil
         success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
             dispatch_async(dispatch_queue_create("data", nil), ^{
                 LocalImageDataSource *dataSource = [[LocalImageDataSource alloc] init];
                 [dataSource insertImagesFromResonseObject:responseObject];
                 for (NSDictionary *picDict in responseObject) {
                     NSString *previewURLString = picDict[PreviewURL];
                     NSString *picTitle         = picDict[PictureTags];
                     NSString *downloadImageURLString = picDict[self.downloadImageTypeKey];
                     NSURL *downloadImageURL = [NSURL URLWithString:downloadImageURLString];
                     Picture *photoPic = [[Picture alloc] initWithURL:downloadImageURL];
                     photoPic.caption = picTitle;
                     [self.photos addObject:photoPic];
                     
                     NSInteger thumbLoadWay = [[NSUserDefaults standardUserDefaults] integerForKey:kThumbLoadWay];
                     switch (thumbLoadWay) {
                         case KonachanPreviewImageLoadTypeLoadPreview:
                             [self.previewPhotosURL addObject:[NSURL URLWithString:previewURLString]];
                             break;
                         case KonachanPreviewImageLoadTypeLoadDownloaded:
                             [self.previewPhotosURL addObject:downloadImageURL];
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
//                         NSLog(@"No images");
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

- (NSString *)downloadImageTypeKey {
    if (!_downloadImageTypeKey) {
        NSInteger downloadImageType = [[NSUserDefaults standardUserDefaults] integerForKey:kDownloadImageType];
        switch (downloadImageType) {
            case KonachanImageDownloadTypeSample:
                _downloadImageTypeKey = SampleURL;
                break;
            case KonachanImageDownloadTypeJPEG:
                _downloadImageTypeKey = JPEGURL;
                break;
            case KonachanImageDownloadTypeFile:
                _downloadImageTypeKey = FileURL;
                break;
            default:
                _downloadImageTypeKey = SampleURL;
                break;
        }
    }
    return _downloadImageTypeKey;
}

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

#pragma mark - Notification

- (void)observeNotifications {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handlePreloadPhotoProgressDidChanged:) name:PreloadPhotoProgressDidChangeNotification object:nil];
}

- (void)handlePreloadPhotoProgressDidChanged:(NSNotification *)noti {
    NSNumber *finised = [noti.userInfo valueForKey:PreloadPhotoProgressFinishedKey];
    NSNumber *total = [noti.userInfo valueForKey:PreloadPhotoProgressTotalKey];
    BOOL completed = [[noti.userInfo valueForKey:PreloadPhotoPrograssCompletedKey] boolValue];
    
    UIBarButtonItem *rightItem;
    NSString *progress;
    if (completed) {
        progress = [NSString stringWithFormat:@""];
    } else {
        progress = [NSString stringWithFormat:@"%@/%@", finised, total];
    }
    rightItem = [[UIBarButtonItem alloc] initWithTitle:progress style:UIBarButtonItemStyleDone target:self action:nil];
    self.navigationItem.rightBarButtonItem = rightItem;
}

#pragma mark - Gestures

- (void)setupGestures {
    UIScreenEdgePanGestureRecognizer *leftEdgeGesture = [[UIScreenEdgePanGestureRecognizer alloc] initWithTarget:self action:@selector(handleLeftEdgeGesture:)];
    leftEdgeGesture.edges = UIRectEdgeLeft;
    [self.collectionView addGestureRecognizer:leftEdgeGesture];
}

- (void)handleLeftEdgeGesture:(UIScreenEdgePanGestureRecognizer *)gesture {
    CGPoint p = [gesture velocityInView:self.collectionView];
    if (p.x > _screenWidth) {
        [self.navigationController popToRootViewControllerAnimated:YES];
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
    NSLog(@"didReceiveMemoryWarning");
    [[SDImageCache sharedImageCache] clearMemory];
    [super didReceiveMemoryWarning];
}

@end
