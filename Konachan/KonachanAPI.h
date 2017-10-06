//
//  KonachanAPI.h
//  Konachan.com API
//  Created by yaqinking on 4/26/15.
//  Copyright (c) 2015 yaqinking. All rights reserved.
//


//Debug mode
//YES = 1 NO = 0
#define IS_DEBUG_MODE 0

//Get Post

//get post with limit per page image and page number and tags
#define KONACHAN_POST_LIMIT_PAGE_TAGS @"http://konachan.com/post.json?limit=%i&page=%i&tags=%@"

//safe mode Konachan
#define KONACHAN_SAFE_MODE_POST_LIMIT_PAGE_TAGS @"http://konachan.com/post.json?limit=%i&page=%i&tags=%@+rating:s"

//yande.re
#define YANDERE_POST_LIMIT_PAGE_TAGS  @"https://yande.re/post.json?limit=%i&page=%i&tags=%@"

//Example
//Get saenai_heroine_no_sodatekata Perpage 10 images
//http://konachan.com/post.json?limit=10&page=1&tags=saenai_heroine_no_sodatekata
//Get saenai_heroine_no_sodatekata Perpage 20 images and Page number is 2
//http://konachan.com/post.json?limit=20&page=2&tags=saenai_heroine_no_sodatekata

//get 10 posted images default max=100 per page
#define KONACHAN_POST_LIMIT_DEFAULT      @"http://konachan.com/post.json?limit=10"

//get 10 posted images set you want display page number
#define KONACHAN_POST_LIMIT_DEFAULT_PAGE @"http://konachan.com/post.json?limit=10&page=%i"

//Download illustrate quality key
static NSString * const PreviewURL = @"preview_url";
static NSString * const SampleURL = @"sample_url";
static NSString * const JPEGURL = @"jpeg_url";
static NSString * const FileURL = @"file_url";

//Get illustrate title/tags key
static NSString * const PictureTags = @"tags";

static NSString * const KonachanShortcutItemAddKeyword = @"moe.yaqinking.Konachan.AddKeyword";
static NSString * const KonachanShortcutItemViewAll    = @"moe.yaqinking.Konachan.ViewAll";
static NSString * const KonachanShortcutItemViewLast   = @"moe.yaqinking.Konachan.ViewLast";
static NSString * const KonachanShortcutItemViewSecond = @"moe.yaqinking.Konachan.ViewSecond";

static NSString * const KonachanSegueIdentifierShowTagPhotos = @"Show Tag Photos";
static NSString * const KonachanDownloadImageTypeDidChangedNotification = @"DownloadImageTypeDidChangedNotification";

//Base URL
static NSString * const Konachan_com = @"https://konachan.com";
static NSString * const Yande_re = @"https://yande.re";

typedef NS_ENUM(NSInteger, KonachanImageDownloadType) {
    KonachanImageDownloadTypeUnseted,
    KonachanImageDownloadTypePreview,
    KonachanImageDownloadTypeSample,
    KonachanImageDownloadTypeJPEG,
    KonachanImageDownloadTypeFile
};

typedef NS_ENUM(NSInteger, KonachanSourceSiteType) {
    KonachanSourceSiteTypeUnseted,
    KonachanSourceSiteTypeKonachan_com,
    KonachanSourceSiteTypeKonachan_net,
    KonachanSourceSiteTypeYande_re
};

typedef NS_ENUM(NSInteger, KonachanPreviewImageLoadType) {
    KonachanPreviewImageLoadTypeUnseted,
    KonachanPreviewImageLoadTypeLoadPreview,
    KonachanPreviewImageLoadTypeLoadDownloaded
};

#define SplitViewScreeniPad_Half           507
#define SplitViewScreeniPad_Slide_Over     320
#define SplitViewScreeniPad_Landscape2_3   694
#define SplitViewScreeniPad_Portrait_1_1_2 438

#define SplitViewScreeniPad_Pro_Half           678
#define SplitViewScreeniPad_Pro_Slide_Over     375
#define SplitViewScreeniPad_Pro_Landscape2_3   981
#define SplitViewScreeniPad_Pro_Portrait_1_1_2 639

#define iPad_Width 768
#define iPad_Pro_Width 1024

#define kFetchAmountDefault    60
#define kFetchAmountMin        40
#define kFetchAmountiPadProMin 75

#define kSourceSite   @"source_site"
#define kFetchAmount  @"fetch_amount"
#define kThumbLoadWay @"thumbLoadWay"
#define kDownloadImageType @"download_type"
#define kPreloadNextPage @"preload_next_page"
#define kSwitchSite @"switch_site"
#define kOfflineMode @"offline_mode"
#define kOpenBlacklist @"open_blacklist"

//Ratings
#define kRatingSafe         @"s"
#define kRatingQuestionable @"q"
#define kRatingExplicit     @"e"

//For device adaption
#define iPadProPortrait ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad && [UIScreen mainScreen].bounds.size.height == 1366)
#define iPadProLandscape ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad && [UIScreen mainScreen].bounds.size.width == 1366)
#define iPadPro_10_5_Portrait ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad && [UIScreen mainScreen].bounds.size.height == 1112)
#define iPadPro_10_5_Landscape ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad && [UIScreen mainScreen].bounds.size.width == 1112)
#define iPad ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
#define iPadPortrait ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad && [UIScreen mainScreen].bounds.size.height == 1024)
#define iPadLandscape ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad && [UIScreen mainScreen].bounds.size.width == 1024)
#define iPhone ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
#define iPhone3_5InchPortrait ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone && [UIScreen mainScreen].bounds.size.height == 480)
#define iPhone3_5InchLandscape ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone && [UIScreen mainScreen].bounds.size.width == 480)
#define iPhone4InchPortrait ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone && [UIScreen mainScreen].bounds.size.height == 568)
#define iPhone4InchLandscape ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone && [UIScreen mainScreen].bounds.size.width == 568)
#define iPhone6Portrait ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone && [UIScreen mainScreen].bounds.size.height == 667)
#define iPhone6Landscape ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone && [UIScreen mainScreen].bounds.size.width == 667)
#define iPhone6PlusPortrait ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone && [UIScreen mainScreen].bounds.size.height == 736)
#define iPhone6PlusLandscape ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone && [UIScreen mainScreen].bounds.size.width == 736)
