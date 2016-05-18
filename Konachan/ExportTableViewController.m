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

@interface ExportTableViewController ()

@property (nonatomic, strong) NSURL *documentsURL;
@property (nonatomic, copy) NSArray<Image *> *cachedImages;

@end

@implementation ExportTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)export:(UIBarButtonItem *)sender {
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
        [self exportImages:imageQualityType.unsignedIntegerValue];
    }];
}

- (void)exportImages:(KonachanImageDownloadType) type {
    __block NSMutableArray<NSString *> *imageKeys = [NSMutableArray new];
    __block NSString *folder;
    switch (type) {
        case KonachanImageDownloadTypeSample:
            [self.cachedImages enumerateObjectsUsingBlock:^(Image * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                [imageKeys addObject:obj.sample_url];
            }];
            folder = @"Sample";
            break;
        case KonachanImageDownloadTypeJPEG:
            [self.cachedImages enumerateObjectsUsingBlock:^(Image * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                [imageKeys addObject:obj.jpeg_url];
            }];
            folder = @"JPEG";
            break;
        case KonachanImageDownloadTypeFile:
            [self.cachedImages enumerateObjectsUsingBlock:^(Image * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                [imageKeys addObject:obj.file_url];
            }];
            folder = @"File";
            break;
        default:
            break;
    }
    [self queryImagesWithKeys:imageKeys toFolder:folder];
}

- (void)queryImagesWithKeys:(NSArray<NSString *> *)imageKeys toFolder:(NSString *)folder{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *folderPath = [self.documentsURL.path stringByAppendingPathComponent:folder];
    if (![fileManager fileExistsAtPath:folderPath]) {
        [fileManager createDirectoryAtPath:folderPath withIntermediateDirectories:NO attributes:nil error:nil];
    }
    [imageKeys enumerateObjectsUsingBlock:^(NSString * _Nonnull key, NSUInteger idx, BOOL * _Nonnull stop) {
        [[SDImageCache sharedImageCache] queryDiskCacheForKey:key done:^(UIImage *image, SDImageCacheType cacheType) {
            if (image) {
                NSString *fileName = [[NSURL URLWithString:key] lastPathComponent];
                NSString *path = [folderPath stringByAppendingPathComponent:fileName];
                if (![fileManager fileExistsAtPath:path]) {
                    [UIImageJPEGRepresentation(image, 1.0) writeToFile:path atomically:YES];
                }
            }
        }];
    }];
}

- (NSURL *)documentsURL {
    if (!_documentsURL) {
        _documentsURL = [(AppDelegate *)[[UIApplication sharedApplication] delegate] applicationDocumentsDirectory];
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

/*
#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
#warning Incomplete implementation, return the number of sections
    return 0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
#warning Incomplete implementation, return the number of rows
    return 0;
}
*/
/*
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:<#@"reuseIdentifier"#> forIndexPath:indexPath];
    
    // Configure the cell...
    
    return cell;
}
*/

@end
