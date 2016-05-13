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

NSString * const PreloadPhotoProgressDidChangeNotification = @"PreloadPhotoProgressDidChangeNotification";
NSString * const PreloadPhotoProgressFinishedKey           = @"finished";
NSString * const PreloadPhotoProgressTotalKey              = @"total";
NSString * const PreloadPhotoPrograssCompletedKey          = @"completed";

@interface PreloadPhotoManager()

@property (nonatomic, strong) NSMutableArray *preferchURLS;
@property (nonatomic, strong) NSString *downloadImageTypeKey;

@end

@implementation PreloadPhotoManager

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
             dispatch_async(dispatch_queue_create("cache_queue", nil), ^{
                 for (NSDictionary *picDict in responseObject) {
                     NSString *previewURLString = picDict[PreviewURL];
                     NSString *downloadImageURLString = picDict[self.downloadImageTypeKey];
                     NSURL *downloadImageURL = [NSURL URLWithString:downloadImageURLString];
                     NSInteger thumbLoadWay = [[NSUserDefaults standardUserDefaults] integerForKey:kThumbLoadWay];
                     switch (thumbLoadWay) {
                         case KonachanPreviewImageLoadTypeLoadPreview:
                             [self.preferchURLS addObject:[NSURL URLWithString:previewURLString]];
                             break;
                         case KonachanPreviewImageLoadTypeLoadDownloaded:
                             [self.preferchURLS addObject:downloadImageURL];
                             break;
                         default:
                             break;
                     }
                 }
                 [fecher prefetchURLs:self.preferchURLS progress:^(NSUInteger noOfFinishedUrls, NSUInteger noOfTotalUrls) {
                     NSNumber *finised = [NSNumber numberWithUnsignedInteger:noOfFinishedUrls];
                     NSNumber *total = [NSNumber numberWithUnsignedInteger:noOfTotalUrls];
                     NSDictionary *userInfo = @{ PreloadPhotoProgressFinishedKey: finised,
                                                 PreloadPhotoProgressTotalKey: total,
                                                 PreloadPhotoPrograssCompletedKey: @NO };
                     [[NSNotificationCenter defaultCenter] postNotificationName:PreloadPhotoProgressDidChangeNotification object:nil userInfo:userInfo];
                 } completed:^(NSUInteger noOfFinishedUrls, NSUInteger noOfSkippedUrls) {
                     [self.preferchURLS removeAllObjects];
                     NSDictionary *userInfo = @{ PreloadPhotoPrograssCompletedKey: @YES };
                     [[NSNotificationCenter defaultCenter] postNotificationName:PreloadPhotoProgressDidChangeNotification object:nil userInfo:userInfo];
                 }];
                 
             });
         } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
             NSLog(@"%@ failure %@",[self class],error);
         }];
}

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

- (NSMutableArray *)preferchURLS {
    if (!_preferchURLS) {
        _preferchURLS = [NSMutableArray new];
    }
    return _preferchURLS;
}

@end
