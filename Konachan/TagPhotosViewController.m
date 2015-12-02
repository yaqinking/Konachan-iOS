//
//  TagPhotosViewController.m
//  Konachan
//
//  Created by 小笠原やきん on 15/8/5.
//  Copyright © 2015年 yaqinking. All rights reserved.
//

#import "TagPhotosViewController.h"
#import "PhotoCell.h"
#import "KonachanAPI.h"
#import "Tag+CoreDataProperties.h"
#import "Picture.h"

#import "AFNetworking.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import "MWPhotoBrowser.h"

#import "SVPullToRefresh.h"
#import "UIImageView+UIActivityIndicatorForSDWebImage.h"

static NSString * const CellIdentifier = @"PhotoCell";

@interface TagPhotosViewController ()

@property (strong, nonatomic) NSMutableArray *photos;
@property (strong, nonatomic) NSMutableArray *photosURL;
@property (nonatomic) BOOL isEnterBrowser;

@end

@implementation TagPhotosViewController


- (void)viewDidLoad {
    [super viewDidLoad];
    self.pageOffset = 1;
    [self setupSourceSite];
    [self setupPhotosURLWithTag:self.tag.name andPageoffset:self.pageOffset];
    //fix first row hide when pull to refresh stop
    if ([self respondsToSelector:@selector(automaticallyAdjustsScrollViewInsets)]) {
        self.automaticallyAdjustsScrollViewInsets = NO;
        
        UIEdgeInsets insets = self.collectionView.contentInset;
        insets.top          = self.navigationController.navigationBar.bounds.size.height +
        [UIApplication sharedApplication].statusBarFrame.size.height;
        self.collectionView.contentInset          = insets;
        self.collectionView.scrollIndicatorInsets = insets;
    }
    __weak TagPhotosViewController *weakSelf = self;
    
    [self.collectionView addInfiniteScrollingWithActionHandler:^{
        [weakSelf setupPhotosURLWithTag:weakSelf.tag.name andPageoffset:weakSelf.pageOffset];
    }];

}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    self.isEnterBrowser = NO;
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    if (!self.isEnterBrowser) {
        [self.photos removeAllObjects];
        self.photos = nil;
        self.photosURL = nil;
    }
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(nonnull UICollectionView *)collectionView {
    return 1;
}

- (nonnull UICollectionViewCell *)collectionView:(nonnull UICollectionView *)collectionView cellForItemAtIndexPath:(nonnull NSIndexPath *)indexPath {
    PhotoCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:CellIdentifier forIndexPath:indexPath];
    NSURL *photoURL = [self.photosURL objectAtIndex:indexPath.row];
    [cell.image setImageWithURL:photoURL usingActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    return cell;
}

- (NSInteger)collectionView:(nonnull UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.photosURL.count;
}

#pragma mark - UICollectionViewDelegate

- (void)collectionView:(nonnull UICollectionView *)collectionView didSelectItemAtIndexPath:(nonnull NSIndexPath *)indexPath {
    self.isEnterBrowser = YES;
    MWPhotoBrowser *browser = [[MWPhotoBrowser alloc] initWithPhotos:self.photos];
    [browser setCurrentPhotoIndex:indexPath.row];
    browser.delegate = self;
    
    browser.enableGrid = NO;
    browser.displayNavArrows = YES;
    browser.zoomPhotosToFill = YES;
    browser.enableSwipeToDismiss = YES;
    
    [self.navigationController pushViewController:browser animated:YES];
}


- (void)setupPhotosURLWithTag:(NSString *)tag andPageoffset:(int)pageOffset {
    NSInteger fetchAmount = [[NSUserDefaults standardUserDefaults] integerForKey:kFetchAmount];
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:self.sourceSite,fetchAmount,pageOffset,tag]];
    self.pageOffset ++;
    
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
    //            NSString *previewURLString = picDict[KONACHAN_DOWNLOAD_TYPE_PREVIEW];
                NSString *sampleURLString  = picDict[KONACHAN_DOWNLOAD_TYPE_SAMPLE];
                NSString *picTitle         = picDict[KONACHAN_KEY_TAGS];
      
                Picture *photoPic = [[Picture alloc] initWithURL:[NSURL URLWithString:sampleURLString]];
                photoPic.caption = picTitle;
                
                [self.photosURL addObject:[NSURL URLWithString:sampleURLString]];
                [self.photos addObject:photoPic];
            }
        
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.collectionView.infiniteScrollingView stopAnimating];
                self.navigationItem.title = [NSString stringWithFormat:@"Total %lu",(unsigned long)self.photos.count];
                [self.collectionView reloadData];
                
                if (IS_DEBUG_MODE) {
                    NSLog(@"count %lu",(unsigned long)self.photosURL.count);
                }
                
            });
            
        });
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"failure %@",error);
        //由于在发送请求之前已经将 pageOffset + 1 ,这里需要 - 1 来保证过几秒之后加载的还是请求失败的页面，毕竟 API 短时间内使用次数有限……
        self.pageOffset --;
        //失败后也要让上拉加载控件 stop
        [self.collectionView.infiniteScrollingView stopAnimating];
    }];
    [[NSOperationQueue mainQueue] addOperation:op];
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


- (NSMutableArray *)photosURL {
    if (!_photosURL) {
        _photosURL = [[NSMutableArray alloc] init];
    }
    return _photosURL;
}

//- (UIStatusBarAnimation)preferredStatusBarUpdateAnimation {
//    return UIStatusBarAnimationFade;
//}

@end
