//
//  ExportTableViewController.m
//  Konachan
//
//  Created by 小笠原やきん on 16/5/18.
//  Copyright © 2016年 yaqinking. All rights reserved.
//

#import "ExportTableViewController.h"
#import "KonachanAPI.h"
#import "AppDelegate.h"
#import "LocalImageDataSource.h"
#import "Image.h"
#import "SDImageCache.h"
#import "MBProgressHUD.h"
#import "KNCCoreDataStackManager.h"

@interface ExportTableViewController ()

@property (nonatomic, strong) NSURL *documentsURL;
@property (nonatomic, copy) NSArray<Image *> *cachedImages;
@property (nonatomic, assign) NSNumber *exportProgress;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *exportButton;
@property (nonatomic, assign) NSUInteger totalCount;
@property (nonatomic, assign) NSUInteger exportedCount;

@end

@implementation ExportTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (IBAction)export:(UIBarButtonItem *)sender {
    dispatch_async(dispatch_queue_create("export queue", 0), ^{
        NSArray<UITableViewCell *> *cells = self.tableView.visibleCells;
        NSMutableArray<NSNumber *> *exportIndexs = [NSMutableArray new];
        [cells enumerateObjectsUsingBlock:^(UITableViewCell * _Nonnull cell, NSUInteger idx, BOOL * _Nonnull stop) {
            switch (cell.accessoryType) {
                case UITableViewCellAccessoryCheckmark:
                    // See KonachanAPI 2 -> Sample, 3 -> JPEG, 4 -> File
                    [exportIndexs addObject:[NSNumber numberWithUnsignedInteger:(idx+2)]];
                    break;
                default:
                    break;
            }
        }];
        
        [exportIndexs enumerateObjectsUsingBlock:^(NSNumber * _Nonnull imageQualityType, NSUInteger idx, BOOL * _Nonnull stop) {
            NSString *key = [self keyWithImageType:imageQualityType];
            NSString *folder = [self folderWithKey:key];
            NSArray *cachedImageKeys = [self cachedImageKeysWithKey:key];
            self.totalCount += cachedImageKeys.count;
            [self queryImagesWithKeys:cachedImageKeys toFolder:folder];
        }];
        
    });
}


- (NSString *)keyWithImageType:(NSNumber *)imageQualityType {
    switch (imageQualityType.unsignedIntegerValue) {
        case KonachanImageDownloadTypeSample:
            return @"sample_url";
            break;
        case KonachanImageDownloadTypeJPEG:
            return @"jpeg_url";
        case KonachanImageDownloadTypeFile:
            return @"file_url";
        default:
            break;
    }
    return nil;
}

- (NSString *)folderWithKey:(NSString *)key {
    if ([key isEqualToString:@"sample_url"]) {
        return @"all_sample";
    } else if ([key isEqualToString:@"jpeg_url"]) {
        return @"all_jpeg";
    } else if ([key isEqualToString:@"file_url"]) {
        return @"all_file";
    }
    return nil;
}

- (NSArray<NSString *> *)cachedImageKeysWithKey:(NSString *)key {
    NSMutableArray *imageKeys = [NSMutableArray new];
    [self.cachedImages enumerateObjectsUsingBlock:^(Image * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [imageKeys addObject:[obj valueForKey:key]];
    }];
    return imageKeys;
}

- (void)queryImagesWithKeys:(NSArray<NSString *> *)imageKeys toFolder:(NSString *)folder{
    __block MBProgressHUD *hud;
    dispatch_async(dispatch_get_main_queue(), ^{
        self.navigationController.view.userInteractionEnabled = NO;
        hud = [MBProgressHUD showHUDAddedTo:self.navigationController.view animated:YES];
        hud.animationType = MBProgressHUDModeAnnularDeterminate;
        hud.labelText = [NSString stringWithFormat:@"Export to %@ folder", folder];
    });
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *folderPath = [self.documentsURL.path stringByAppendingPathComponent:folder];
    if (![fileManager fileExistsAtPath:folderPath]) {
        [fileManager createDirectoryAtPath:folderPath withIntermediateDirectories:NO attributes:nil error:nil];
    }
    [imageKeys enumerateObjectsUsingBlock:^(NSString * _Nonnull key, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString *cachePath = [[SDImageCache sharedImageCache] defaultCachePathForKey:key];
        if (cachePath) {
            NSString *fileName = [[NSURL URLWithString:key] lastPathComponent];
            NSString *path = [folderPath stringByAppendingPathComponent:fileName];
            if (![fileManager fileExistsAtPath:path]) {
                NSError *error = nil;
                if(![fileManager copyItemAtPath:cachePath toPath:path error:&error]) {
//                        NSLog(@"Copy %@ to %@ Error %@",cachePath, path, [error localizedDescription]);
                }
            }
        }
        self.exportedCount += 1;
        dispatch_async(dispatch_get_main_queue(), ^{
            hud.detailsLabelText = [NSString stringWithFormat:@"%li/%li\nYou can use iTunes to copy exported images folder to your Mac/PC.",self.exportedCount, self.totalCount];
            if (idx == (imageKeys.count - 1)) {
                hud.hidden = YES;
                self.totalCount -= imageKeys.count;
                self.exportedCount -= imageKeys.count;
                self.navigationController.view.userInteractionEnabled = YES;
            }
        });
    }];
}

- (NSURL *)documentsURL {
    if (!_documentsURL) {
        _documentsURL = [[KNCCoreDataStackManager sharedManager] applicationDocumentsDirectory];
    }
    return _documentsURL;
}

- (NSArray<Image *> *)cachedImages {
    if (!_cachedImages) {
        _cachedImages = [[LocalImageDataSource alloc] imagesWithTag:@""];
    }
    return _cachedImages;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    if (cell.accessoryType == UITableViewCellAccessoryNone) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
}

@end
