//
//  PreloadPhotoManager.m
//  Konachan
//
//  Created by 小笠原やきん on 4/1/16.
//  Copyright © 2016 yaqinking. All rights reserved.
//

#import "PreloadPhotoManager.h"
#import "SDWebImagePrefetcher.h"
#import "AFNetworking.h"
#import "KonachanAPI.h"

NSString * const KonachanNeedClearPrefechNotification = @"KonachanNeedClearPrefechNotification";

@interface PreloadPhotoManager()

@property (nonatomic, strong) NSMutableArray *preferchURLS;

@end

@implementation PreloadPhotoManager

- (instancetype)init {
    self = [super init];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleClearPrefech)
                                                     name:KonachanNeedClearPrefechNotification
                                                   object:nil];
    }
    return self;
}

- (void)handleClearPrefech {
    [self.preferchURLS removeAllObjects];
}

+ (PreloadPhotoManager *)manager {
    static PreloadPhotoManager *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[PreloadPhotoManager alloc] init];
    });
    return sharedInstance;
}

- (void)GET:(NSString *)url {
    SDWebImagePrefetcher *fecher = [SDWebImagePrefetcher sharedImagePrefetcher];
    fecher.maxConcurrentDownloads = 5;
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
                     NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
                     NSInteger downloadImageType = [userDefaults integerForKey:kDownloadImageType];
                     
                     
                     NSInteger thumbLoadWay = [[NSUserDefaults standardUserDefaults] integerForKey:kThumbLoadWay];
                     
                     switch (thumbLoadWay) {
                         case KonachanPreviewImageLoadTypeLoadPreview:
                             [self.preferchURLS addObject:[NSURL URLWithString:previewURLString]];
                             break;
                         case KonachanPreviewImageLoadTypeLoadDownloaded:
                             switch (downloadImageType) {
                                 case KonachanImageDownloadTypeSample:
                                     [self.preferchURLS addObject:[NSURL URLWithString:sampleURLString]];
                                     break;
                                 case KonachanImageDownloadTypeJPEG:
                                     [self.preferchURLS addObject:[NSURL URLWithString:jpegURLString]];
                                     break;
                                 case KonachanImageDownloadTypeFile:
                                     [self.preferchURLS addObject:[NSURL URLWithString:fileURLString]];
                                     break;
                                 default:
                                     break;
                             }
                             break;
                         default:
                             break;
                     }
                 }
                 [fecher prefetchURLs:self.preferchURLS progress:^(NSUInteger noOfFinishedUrls, NSUInteger noOfTotalUrls) {
//                     NSLog(@"Progress Finised %i Total %i",noOfFinishedUrls, noOfTotalUrls);
                 } completed:^(NSUInteger noOfFinishedUrls, NSUInteger noOfSkippedUrls) {
//                     NSLog(@"Completed Finised %i Skipped %i",noOfFinishedUrls, noOfSkippedUrls);
                 }];
                 
             });
         } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
             NSLog(@"%@ failure %@",[self class],error);
         }];
}

- (NSMutableArray *)preferchURLS {
    if (!_preferchURLS) {
        _preferchURLS = [NSMutableArray new];
    }
    return _preferchURLS;
}

@end
