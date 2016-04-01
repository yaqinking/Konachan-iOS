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

static NSString * const CellIdentifier = @"PhotoCell";
NSString * const TagAll = @"";

@interface TagPhotosViewController ()

@property (strong, nonatomic) NSMutableArray *photos;
@property (strong, nonatomic) NSMutableArray *previewPhotosURL;

@property (strong, nonatomic) MWPhotoBrowser *browser;

@property (nonatomic, assign, getter=isEnterBrowser) BOOL enterBrowser;
@property (nonatomic, assign, getter=isLoadNextPage) BOOL loadNextPage;

@property (nonatomic, assign) NSInteger fetchAmount;
@property (nonatomic, assign) NSUInteger currentIndex;

@end

@implementation TagPhotosViewController

#pragma mark - Life cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    self.pageOffset = 1;
    self.loadNextPage = NO;
    self.currentIndex = 0;
    [self setupPhotosURLWithTag:self.tag.name andPageoffset:self.pageOffset];
    
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    self.enterBrowser = NO;
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    if (self.enterBrowser) {
        [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:self.currentIndex inSection:0]
                                    atScrollPosition:UICollectionViewScrollPositionTop
                                            animated:NO];
    }
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    if (!self.isEnterBrowser) {
        self.photos = nil;
        self.previewPhotosURL = nil;
    }
}

#pragma mark - Scroll view delegate

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView{
    float endScrolling = scrollView.contentOffset.y + scrollView.frame.size.height;
    
    if (endScrolling >= scrollView.contentSize.height){
        if (self.isLoadNextPage) {
//            NSLog(@"loadNextPageData......");
            [self setupPhotosURLWithTag:self.tag.name andPageoffset:self.pageOffset];
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
    [cell.image sd_setImageWithURL:photoURL completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
        if (error) {
//            [cell.image setImage:[UIImage imageNamed:@"placeholder"]];
        }
    } usingProgressView:nil];
    return cell;
}

- (NSInteger)collectionView:(nonnull UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.previewPhotosURL.count;
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
             NSLog(@"Manager Thred %@",[NSThread currentThread]);
             dispatch_async(dispatch_queue_create("data", nil), ^{
                 NSLog(@"Data Start Process %@",[NSThread currentThread]);
                 for (NSDictionary *picDict in responseObject) {
                     NSString *previewURLString = picDict[PreviewURL];
                     NSString *sampleURLString  = picDict[SampleURL];
                     NSString *jpegURLString = picDict[JPEGURL];
                     NSString *fileURLString = picDict[FileURL];
                     NSString *picTitle         = picDict[PictureTags];
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
                     NSLog(@"Data processed %@",[NSThread currentThread]);
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
        NSString *nextPage;
        if ([self isCurrentLoadAllWithTag:tag]) {
            nextPage = [NSString stringWithFormat:self.sourceSite, self.fetchAmount, pageOffset+1, TagAll];
        } else {
            nextPage = [NSString stringWithFormat:self.sourceSite, self.fetchAmount, pageOffset+1, tag];
        }
        NSLog(@"Next Page URL String %@",nextPage);
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
    if (index >= (self.photos.count - 6)) {
//        NSLog(@"Load More");
        if (self.isLoadNextPage) {
//            NSLog(@"Load More");
            [self setupPhotosURLWithTag:self.tag.name andPageoffset:self.pageOffset];
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

@end
