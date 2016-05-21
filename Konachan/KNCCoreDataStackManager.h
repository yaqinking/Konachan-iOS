//
//  KNCCoreDataStackManager.h
//  Konachan
//
//  Created by 小笠原やきん on 16/5/20.
//  Copyright © 2016年 yaqinking. All rights reserved.
//

#import <Foundation/Foundation.h>

@import CoreData;

@class Tag;
@class Image;

@interface KNCCoreDataStackManager : NSObject

@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (readonly, strong, nonatomic) NSPersistentStore *cachePersistentStore;

+ (instancetype)sharedManager;

- (NSArray<Tag *> *)savedTags;

- (void)saveContext;
- (NSURL *)applicationDocumentsDirectory;

- (NSArray<Image *> *)cachedImagesUsingPredicate:(NSPredicate *)predicate;
- (NSArray<Image *> *)cachedImages;

@end
