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
#import "Tag.h"

@interface ExportTableViewController ()

@property (nonatomic, strong) NSURL *documentsURL;
@property (nonatomic, copy) NSArray<Image *> *cachedImages;
@property (nonatomic, assign) NSNumber *exportProgress;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *exportButton;
@property (nonatomic, assign) NSUInteger totalCount;
@property (nonatomic, assign) NSUInteger exportedCount;
@property (nonatomic, strong) NSArray *sectionDatas;
@property (nonatomic, strong) NSArray *sectionFooterDatas;
@property (nonatomic, strong) NSArray *tags;
@property (nonatomic, strong) NSArray *imageQulities;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSDictionary *> *exportDictionary;

@end

@implementation ExportTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.sectionDatas = @[@"Image Quality", @"Tag"];
    self.imageQulities = @[@"Sample", @"JPEG", @"File"];
    self.tags = [[KNCCoreDataStackManager sharedManager] savedTags];
    self.exportDictionary = [NSMutableDictionary new];
    self.sectionFooterDatas = @[@"At least, you need select one image quality and one tag to export. You can select multiple tags and different qualities to export.",@"You can use iTunes to copy exported images to your Mac or PC."];
    self.exportButton.enabled = self.tags.count == 0 ? NO : YES;
}

- (IBAction)export:(UIBarButtonItem *)sender {
    dispatch_async(dispatch_queue_create("export queue", 0), ^{
        __block NSMutableArray<NSString *> *exportImageQulities = [NSMutableArray new];
        __block NSMutableArray<NSString *> *exportTags = [NSMutableArray new];
        [self.exportDictionary enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSDictionary * _Nonnull obj, BOOL * _Nonnull stop) {
            NSString *exportKey = @"export";
            NSString *sectionKey = @"section";
            BOOL isExport = [[obj valueForKey:exportKey] boolValue];
            NSInteger section = [[obj valueForKey:sectionKey] integerValue];
            if (section == 0 && isExport) {
                [exportImageQulities addObject:key];
            } else if (section == 1 && isExport){
                [exportTags addObject:key];
            }
        }];
        if (exportImageQulities.count < 1 && exportTags.count < 1) {
            return ;
        }
        [exportImageQulities enumerateObjectsUsingBlock:^(NSString * _Nonnull imageQuality, NSUInteger idx, BOOL * _Nonnull stop) {
            [exportTags enumerateObjectsUsingBlock:^(NSString * _Nonnull tag, NSUInteger idx, BOOL * _Nonnull stop) {
                NSArray<Image *> *cachedImages;
                if ([tag isEqualToString:@"post"] || [tag isEqualToString:@"all"]) {
                    cachedImages = [[KNCCoreDataStackManager sharedManager] cachedImages];
                } else {
                    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"tags CONTAINS %@", tag];
                    cachedImages = [[KNCCoreDataStackManager sharedManager] cachedImagesUsingPredicate:predicate];
                }
                NSString *folder = [NSString stringWithFormat:@"%@_%@",tag, [self qualityFolderWithImageQuality:imageQuality]];
                NSString *imageQualityKey = [self keyWithImageQuality:imageQuality];
                NSArray<NSString *> *cachedImageKeys = [self cachedImageKeysFrom:cachedImages WithKey:imageQualityKey];
                self.totalCount += cachedImageKeys.count;
                [self queryImagesWithKeys:cachedImageKeys toFolder:folder];
            }];
        }];
    });
}

- (NSString *)keyWithImageQuality:(NSString *)imageQuality {
    if ([imageQuality isEqualToString:@"Sample"]) {
        return @"sample_url";
    }
    if ([imageQuality isEqualToString:@"JPEG"]) {
        return @"jpeg_url";
    }
    if ([imageQuality isEqualToString:@"File"]) {
        return @"file_url";
    }
    return nil;
}

- (NSString *)qualityFolderWithImageQuality:(NSString *)imageQuality {
    if ([imageQuality isEqualToString:@"Sample"]) {
        return @"sample";
    }
    if ([imageQuality isEqualToString:@"JPEG"]) {
        return @"jpeg";
    }
    if ([imageQuality isEqualToString:@"File"]) {
        return @"file";
    }
    return nil;
}

- (NSArray<NSString *> *)cachedImageKeysFrom:(NSArray<Image *> *)images WithKey:(NSString *)key {
    NSMutableArray *imageKeys = [NSMutableArray new];
    [images enumerateObjectsUsingBlock:^(Image * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
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

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.sectionDatas.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return section == 1 ? ( self.tags.count == 0 ? [NSString stringWithFormat:@"Tag\nYou have no tags to show.\nYou can't export any images at this moment. :("] : self.sectionDatas[section]) : (self.sectionDatas[section]);
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    return self.sectionFooterDatas[section];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return section == 0 ? self.imageQulities.count : self.tags.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Export Cell Identifier" forIndexPath:indexPath];
    Tag *tag;
    switch (indexPath.section) {
        case 0:
            cell.textLabel.text = self.imageQulities[indexPath.row];
            break;
        case 1:
            tag = self.tags[indexPath.row];
            cell.textLabel.text = tag.name;
            break;
        default:
            break;
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    NSString *key = cell.textLabel.text;
    NSNumber *section = [NSNumber numberWithInteger:indexPath.section];
    if (cell.accessoryType == UITableViewCellAccessoryNone) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
        NSDictionary *value = @{ @"section" : section,
                                 @"export" : @YES};
        [self.exportDictionary setValue:value forKey:key];
    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
        NSDictionary *value = @{ @"section" : section,
                                 @"export" : @NO };
        [self.exportDictionary setValue:value forKey:key];
    }
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
