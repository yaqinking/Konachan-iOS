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

static NSString * const CellIdentifier = @"PhotoCell";

@interface TagPhotosViewController ()

@property (strong, nonatomic) NSMutableArray *photos;
@property (strong, nonatomic) NSMutableArray *previewPhotosURL;

@property (strong, nonatomic) MWPhotoBrowser *browser;

@property (nonatomic, assign, getter=isEnterBrowser) BOOL enterBrowser;
@property (nonatomic, assign, getter=isLoadNextPage) BOOL loadNextPage;
@property (nonatomic, assign) NSInteger fetchAmount;

@end

@implementation TagPhotosViewController

#pragma mark - Life cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    self.pageOffset = 1;
    self.loadNextPage = NO;
    [self setupSourceSite];
    [self setupPhotosURLWithTag:self.tag.name andPageoffset:self.pageOffset];
    
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    self.enterBrowser = NO;
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    if (!self.isEnterBrowser) {
        [self.photos removeAllObjects];
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
    [cell.image setImageWithURL:photoURL usingActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
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
    [self.navigationController pushViewController:self.browser animated:YES];
}

#pragma mark - Load photos

- (void)setupPhotosURLWithTag:(NSString *)tag andPageoffset:(int)pageOffset {
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:self.sourceSite,self.fetchAmount,pageOffset,tag]];
    self.pageOffset ++;
    self.loadNextPage = NO;
    NSUInteger beforeReqPhotosCount = self.previewPhotosURL.count;
    
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
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
        dispatch_async(dispatch_queue_create("data", nil), ^{
            for (NSDictionary *picDict in responseObject) {
                NSString *previewURLString = picDict[KONACHAN_DOWNLOAD_TYPE_PREVIEW];
                NSString *sampleURLString  = picDict[KONACHAN_DOWNLOAD_TYPE_SAMPLE];
                NSString *jpegURLString = picDict[KONACHAN_DOWNLOAD_TYPE_JPEG];
                NSString *fileURLString = picDict[KONACHAN_DOWNLOAD_TYPE_FILE];
                NSString *picTitle         = picDict[KONACHAN_KEY_TAGS];
                NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
                NSString *downloadImageType = [userDefaults valueForKey:kDownloadImageType];
                
                Picture *photoPic = nil;
                if ([downloadImageType isEqualToString:KONACHAN_DOWNLOAD_TYPE_SAMPLE]) {
                    photoPic = [[Picture alloc] initWithURL:[NSURL URLWithString:sampleURLString]];
                } else if ([downloadImageType isEqualToString:KONACHAN_DOWNLOAD_TYPE_JPEG]) {
                    photoPic = [[Picture alloc] initWithURL:[NSURL URLWithString:jpegURLString]];
                } else if ([downloadImageType isEqualToString:KONACHAN_DOWNLOAD_TYPE_FILE]) {
                    photoPic = [[Picture alloc] initWithURL:[NSURL URLWithString:fileURLString]];
                }
                
                photoPic.caption = picTitle;
                if (IS_DEBUG_MODE) {
//                    NSLog(@"Sample URL %@",sampleURLString);
//                    NSLog(@"Preview URL %@",previewURLString);
                }
                
                NSString *thumbLoadWay = [[NSUserDefaults standardUserDefaults] valueForKey:kThumbLoadWay];
                if ([thumbLoadWay isEqualToString:kLoadThumb]) {
                    [self.previewPhotosURL addObject:[NSURL URLWithString:previewURLString]];
                } else if ([thumbLoadWay isEqualToString:kPredownloadPicture]) {
                    [self.previewPhotosURL addObject:[NSURL URLWithString:sampleURLString]];
                }
                
                [self.photos addObject:photoPic];
            }
            NSUInteger afterReqPhotosCount = self.previewPhotosURL.count;
            self.loadNextPage = YES;
            dispatch_async(dispatch_get_main_queue(), ^{
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
                
                if (IS_DEBUG_MODE) {
                    NSLog(@"count %lu",(unsigned long)self.previewPhotosURL.count);
                }
                
            });
            
        });
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"failure %@",error);
        self.navigationItem.title = @"No images";
        [self showHUDWithTitle:@"Error" content:@"Connection reset by peer."];
        //由于在发送请求之前已经将 pageOffset + 1 ,这里需要 - 1 来保证过几秒之后加载的还是请求失败的页面，毕竟 API 短时间内使用次数有限……
        self.pageOffset --;
        self.loadNextPage = YES;
        //失败后也要让上拉加载控件 stop
//        [self.loadPhotosControl endRefreshing];
    }];
    [[NSOperationQueue mainQueue] addOperation:op];
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
- (void)setupSourceSite {
    NSString *sourceSiteShort = [[NSUserDefaults standardUserDefaults] stringForKey:kSourceSite];
//    NSLog(@"sourceSiteShort \n *** %@",sourceSiteShort);
    if (sourceSiteShort == nil) {
        self.sourceSite = KONACHAN_POST_LIMIT_PAGE_TAGS;
//        NSLog(@"default set to konachan.com");
    } else if ([sourceSiteShort isEqualToString:kKonachanMain]) {
        self.sourceSite = KONACHAN_POST_LIMIT_PAGE_TAGS;
    } else if ([sourceSiteShort isEqualToString:kKonachanSafe]) {
        self.sourceSite = KONACHAN_SAFE_MODE_POST_LIMIT_PAGE_TAGS;
    } else if ([sourceSiteShort isEqualToString:kYandere]) {
        self.sourceSite = YANDERE_POST_LIMIT_PAGE_TAGS;
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

@end
