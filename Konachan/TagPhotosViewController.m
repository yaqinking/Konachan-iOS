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
#import "Tag.h"
#import "Picture.h"

#import "AFNetworking.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import "MWPhotoBrowser.h"

#import "SVPullToRefresh.h"

static NSString * const CellIdentifier = @"PhotoCell";

@interface TagPhotosViewController ()

@property (strong, nonatomic) NSMutableArray *dataPhotos;
@property (strong, nonatomic) NSMutableArray *dataPhotosURL;

@end

@implementation TagPhotosViewController


- (void)viewDidLoad {
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
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(nonnull UICollectionView *)collectionView {
    return 1;
}

- (nonnull UICollectionViewCell *)collectionView:(nonnull UICollectionView *)collectionView cellForItemAtIndexPath:(nonnull NSIndexPath *)indexPath {
    PhotoCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:CellIdentifier forIndexPath:indexPath];
    NSURL *photoURL = [self.photosURL objectAtIndex:indexPath.row];
//    cell.image.image = [UIImage imageNamed:@"ph.jpeg"];
    [cell.image sd_setImageWithURL:photoURL placeholderImage:[UIImage imageNamed:@"ph.jpeg"]];
    return cell;
}

- (NSInteger)collectionView:(nonnull UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.photosURL.count;
}

#pragma mark - UICollectionViewDelegate

- (void)collectionView:(nonnull UICollectionView *)collectionView didSelectItemAtIndexPath:(nonnull NSIndexPath *)indexPath {
    NSMutableArray *photosArray = [[NSMutableArray alloc] init];
    for (NSURL *photoURL in self.photosURL) {
        MWPhoto *photo = [MWPhoto photoWithURL:photoURL];
        [photosArray addObject:photo];
    }
    
    MWPhotoBrowser *browser = [[MWPhotoBrowser alloc] initWithPhotos:photosArray];
    [browser setCurrentPhotoIndex:indexPath.row];
    browser.delegate = self;
    
    browser.enableGrid = NO;
    browser.displayNavArrows = YES;
    browser.zoomPhotosToFill = YES;
    browser.enableSwipeToDismiss = YES;
    
    [self.navigationController pushViewController:browser animated:YES];
}


- (void)setupPhotosURLWithTag:(NSString *)tag andPageoffset:(int)pageOffset {
    
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:self.sourceSite,FETCH_AMOUNT,pageOffset,tag]];
    self.pageOffset ++;
    
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    NSLog(@"url %@",url);
    AFHTTPRequestOperation *op = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    op.responseSerializer = [AFJSONResponseSerializer serializer];
    [op setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        for (NSDictionary *picDict in responseObject) {
//            NSString *previewURLString = picDict[KONACHAN_DOWNLOAD_TYPE_PREVIEW];
            NSString *sampleURLString  = picDict[KONACHAN_DOWNLOAD_TYPE_SAMPLE];
            NSString *picTitle         = picDict[KONACHAN_KEY_TAGS];
  
            Picture *photoPic = [[Picture alloc] initWithURL:[NSURL URLWithString:sampleURLString]];
            photoPic.caption = picTitle;
            
            [self.dataPhotosURL addObject:[NSURL URLWithString:sampleURLString]];
            [self.dataPhotos addObject:photoPic];
        }
        
        self.photosURL = [self.dataPhotosURL copy];
        self.photos = [self.dataPhotos copy];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.collectionView reloadData];
            [self.collectionView.infiniteScrollingView stopAnimating];
        });
        
        NSLog(@"count %lu",(unsigned long)self.photosURL.count);
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"failure %@",error);
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

- (NSMutableArray *)dataPhotos {
    if (!_dataPhotos) {
        _dataPhotos = [[NSMutableArray alloc] init];
    }
    return _dataPhotos;
}

- (NSArray *)photos {
    if (!_photos) {
        _photos = [[NSArray alloc] init];
    }
    return _photos;
}

- (NSMutableArray *)dataPhotosURL {
    if (!_dataPhotosURL) {
        _dataPhotosURL = [[NSMutableArray alloc] init];
    }
    return _dataPhotosURL;
}

- (NSArray *)photosURL {
    if (!_photosURL) {
        _photosURL = [[NSArray alloc] init];
    }
    return _photosURL;
}

//- (UIStatusBarAnimation)preferredStatusBarUpdateAnimation {
//    return UIStatusBarAnimationFade;
//}

@end
