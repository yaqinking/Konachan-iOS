//
//  LocalImageDataSource.m
//  Konachan
//
//  Created by 小笠原やきん on 16/5/13.
//  Copyright © 2016年 yaqinking. All rights reserved.
//

#import "LocalImageDataSource.h"
#import "KonachanAPI.h"
#import "Image.h"
#import "AppDelegate.h"
#import "Picture.h"

@interface LocalImageDataSource()

@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, strong) NSPersistentStore *cachePersistentStore;

@end

@implementation LocalImageDataSource

- (NSString *)fliterWithTag:(NSString *)tag {
    return ([tag isEqualToString:@"post"] || [tag isEqualToString:@"all"]) ? @"": tag;
}

- (NSDictionary *)imageDataDictionaryWithTag:(NSString *)tag {
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Image"];
    NSString *fliter = [self fliterWithTag:tag];
    if (fliter.length != 0) {
        request.predicate = [NSPredicate predicateWithFormat:@"tags CONTAINS %@", fliter];
    }
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"image_id" ascending:NO];
    request.sortDescriptors = @[sortDescriptor];
    NSArray<Image *> *fetchedResults = [self.managedObjectContext executeFetchRequest:request error:nil];
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    __block NSInteger downloadImageType = [userDefaults integerForKey:kDownloadImageType];
    __block NSInteger thumbLoadWay = [[NSUserDefaults standardUserDefaults] integerForKey:kThumbLoadWay];
    
    __block NSMutableArray<NSURL *> *previewURLs = [NSMutableArray new];
    __block NSMutableArray<Picture *> *photos = [NSMutableArray new];
    [fetchedResults enumerateObjectsUsingBlock:^(Image * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        Picture *photoPic;
        switch (downloadImageType) {
            case KonachanImageDownloadTypeSample:
                photoPic = [[Picture alloc] initWithURL:[NSURL URLWithString:obj.sample_url]];
                break;
            case KonachanImageDownloadTypeJPEG:
                photoPic = [[Picture alloc] initWithURL:[NSURL URLWithString:obj.jpeg_url]];
                break;
            case KonachanImageDownloadTypeFile:
                photoPic = [[Picture alloc] initWithURL:[NSURL URLWithString:obj.file_url]];
                break;
            default:
                photoPic = [[Picture alloc] initWithURL:[NSURL URLWithString:obj.sample_url]];
                break;
        }
        photoPic.caption = obj.tags;
        [photos addObject:photoPic];
        
        switch (thumbLoadWay) {
            case KonachanPreviewImageLoadTypeLoadPreview:
                [previewURLs addObject:[NSURL URLWithString:obj.preview_url]];
                break;
            case KonachanPreviewImageLoadTypeLoadDownloaded:
                switch (downloadImageType) {
                    case KonachanImageDownloadTypeSample:
                        [previewURLs addObject:[NSURL URLWithString:obj.sample_url]];
                        break;
                    case KonachanImageDownloadTypeJPEG:
                        [previewURLs addObject:[NSURL URLWithString:obj.jpeg_url]];
                        break;
                    case KonachanImageDownloadTypeFile:
                        [previewURLs addObject:[NSURL URLWithString:obj.file_url]];
                        break;
                    default:
                        break;
                }
                break;
            default:
                break;
        }
    }];
    NSDictionary *dataDictionary = @{@"preview_urls": previewURLs,
                                     @"photos": photos};
    return dataDictionary;
}

- (void)insertImagesFromResonseObject:(id)responseObject {
    //由于这里是从 TagPhotosViewController 创建的 data queue 里过来的，而 MOC（ManagedObjectContext） 不能在非创建时的 queue 里使用，有一定几率（数据变化量大的话，绝对）会出现 *** Terminating app due to uncaught exception 'NSGenericException', reason: '*** Collection <__NSCFSet: 0x5e0b930> was mutated while being enumerated... 错误，而我这个 MOC 是 main queue 的，So，返回主线程执行。
    if ([responseObject isKindOfClass:[NSArray class]]) {
        [responseObject enumerateObjectsUsingBlock:^(NSDictionary *picDict, NSUInteger idx, BOOL * _Nonnull stop) {
            NSString *previewURLString = picDict[PreviewURL];
            NSString *sampleURLString  = picDict[SampleURL];
            NSString *jpegURLString = picDict[JPEGURL];
            NSString *fileURLString = picDict[FileURL];
            NSString *picTitle         = picDict[PictureTags];
            NSString *md5 = picDict[@"md5"];
            NSInteger create_at = [picDict[@"created_at"] integerValue];
            NSInteger image_id = [picDict[@"id"] integerValue];
            NSString *rating = picDict[@"rating"];
            
            NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Image"];
            request.predicate = [NSPredicate predicateWithFormat:@"image_id == %i",image_id];
            dispatch_sync(dispatch_get_main_queue(), ^{
                NSArray *fetchedImages = [[self.managedObjectContext executeFetchRequest:request error:NULL] copy];
                if (fetchedImages.count == 0) {
                    Image *image = [NSEntityDescription insertNewObjectForEntityForName:@"Image" inManagedObjectContext:self.managedObjectContext];
                    image.image_id = [NSNumber numberWithInteger:image_id];
                    image.create_at = [NSNumber numberWithInteger:create_at];
                    image.md5 = md5;
                    image.tags = picTitle;
                    image.preview_url = previewURLString;
                    image.sample_url = sampleURLString;
                    image.file_url = fileURLString;
                    image.jpeg_url = jpegURLString;
                    image.rating = rating;
                    [self.managedObjectContext assignObject:image toPersistentStore:self.cachePersistentStore];
                } else {
                    *stop = YES;
                }
            });
        }];
        dispatch_sync(dispatch_get_main_queue(), ^{
            [self saveChanges];
        });
    }
}

- (void)clearImages {
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Image"];
    NSArray<Image *> *fetchedResults = [self.managedObjectContext executeFetchRequest:request error:nil];
    [fetchedResults enumerateObjectsUsingBlock:^(Image * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [self.managedObjectContext deleteObject:obj];
    }];
    [self saveChanges];
}

- (void)saveChanges {
    if ([self.managedObjectContext hasChanges]) {
        NSError *error = nil;
        if (![self.managedObjectContext save:&error]) {
            NSLog(@"Local Image Data Source Error when saving %@", [error localizedDescription]);
        }
    }
}

- (NSManagedObjectContext *)managedObjectContext {
    if (!_managedObjectContext) {
        AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
        _managedObjectContext = appDelegate.managedObjectContext;
    }
    return _managedObjectContext;
}

- (NSPersistentStore *)cachePersistentStore {
    if (!_cachePersistentStore) {
        AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
        _cachePersistentStore = appDelegate.cachePersistentStore;
    }
    return _cachePersistentStore;
}

@end
