//
//  KNCCoreDataStackManager.m
//  Konachan
//
//  Created by 小笠原やきん on 16/5/20.
//  Copyright © 2016年 yaqinking. All rights reserved.
//

#import "KNCCoreDataStackManager.h"
#import "KonachanAPI.h"
#import "Tag.h"

@implementation KNCCoreDataStackManager

@synthesize managedObjectContext = _managedObjectContext;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;

NSString *const ErrorDomain = @"yaqinking.moe";
NSString *const ContentNameKey = @"moe~yaqinking~konachan";
NSString *const ApplicationDocumentsDirectoryName = @"konachan.sqlite";
NSString *const ApplicationCacheDirectoryName = @"konachan-cache.sqlite";

+ (instancetype)sharedManager {
    static KNCCoreDataStackManager *sharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManager = [[self alloc] init];
    });
    return sharedManager;
}

- (NSURL *)applicationDocumentsDirectory {
    // The directory the application uses to store the Core Data store file. This code uses a directory named "moe.yaqinking.Konachan" in the application's documents directory.
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

- (NSManagedObjectModel *)managedObjectModel {
    // The managed object model for the application. It is a fatal error for the application not to be able to find and load its model.
    if (_managedObjectModel != nil) {
        return _managedObjectModel;
    }
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"Konachan" withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
    // The persistent store coordinator for the application. This implementation creates and returns a coordinator, having added the store for the application to it.
    if (_persistentStoreCoordinator != nil) {
        return _persistentStoreCoordinator;
    }
    
    // Create the coordinator and store
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:ApplicationDocumentsDirectoryName];
    if (IS_DEBUG_MODE) {
        NSLog(@"storeURL %@",storeURL);
    }
    NSDictionary *storeOptions = @{NSPersistentStoreUbiquitousContentNameKey: ContentNameKey,
                                   NSMigratePersistentStoresAutomaticallyOption: @YES,
                                   NSInferMappingModelAutomaticallyOption: @YES};
    NSError *error = nil;
    NSString *failureReason = @"There was an error creating or loading the application's saved data.";
    NSPersistentStore *store = nil;
    if (! (store = [ _persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType
                                                              configuration:nil
                                                                        URL:storeURL
                                                                    options:storeOptions
                                                                      error:&error])) {
        // Report any error we got.
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        dict[NSLocalizedDescriptionKey] = @"Failed to initialize the application's saved data";
        dict[NSLocalizedFailureReasonErrorKey] = failureReason;
        dict[NSUnderlyingErrorKey] = error;
        error = [NSError errorWithDomain:ErrorDomain code:9999 userInfo:dict];
        // Replace this with code to handle the error appropriately.
        // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    
    // Create cache store to save SDWebImage fetched images key, when user switch to local browser mode fetch all images key as data source (Maybe create a new MWPhotobrowser is the good choice?)
    NSURL *cacheStoreURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:ApplicationCacheDirectoryName];
    if (IS_DEBUG_MODE) {
        NSLog(@"Cache Store URL %@", cacheStoreURL);
    }
    NSDictionary *cacheStoreOptions = @{NSMigratePersistentStoresAutomaticallyOption: @YES,
                                        NSInferMappingModelAutomaticallyOption: @YES};
    NSPersistentStore *cacheStore = nil;
    NSError *cacheError = nil;
    if (! (cacheStore = [ _persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType
                                                                   configuration:@"Cache"
                                                                             URL:cacheStoreURL
                                                                         options:cacheStoreOptions
                                                                           error:&cacheError])) {
        // Report any error we got.
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        dict[NSLocalizedDescriptionKey] = @"Failed to initialize the application's cached data";
        dict[NSLocalizedFailureReasonErrorKey] = failureReason;
        dict[NSUnderlyingErrorKey] = error;
        error = [NSError errorWithDomain:ErrorDomain code:9235 userInfo:dict];
        // Replace this with code to handle the error appropriately.
        // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
        NSLog(@"Unresolved cache error %@, %@", error, [error userInfo]);
        abort();
    }
    
    if (IS_DEBUG_MODE) {
        NSURL *finaliCloudURL = [store URL];
        NSLog(@"finaliCloudURL: %@", finaliCloudURL);
        NSURL *finalCacheStoreURL = [cacheStore URL];
        NSLog(@"Cache Store URL %@", finalCacheStoreURL);
    }
    return _persistentStoreCoordinator;
}

- (NSPersistentStore *)cachePersistentStore {
    return [_persistentStoreCoordinator.persistentStores lastObject];
}

- (NSManagedObjectContext *)managedObjectContext {
    // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.)
    if (_managedObjectContext != nil) {
        return _managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (!coordinator) {
        return nil;
    }
    _managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    [_managedObjectContext setPersistentStoreCoordinator:coordinator];
    return _managedObjectContext;
}

- (NSArray<Tag *> *)savedTags {
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Tag"];
    request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"createDate" ascending:YES]];
    return [self.managedObjectContext executeFetchRequest:request error:NULL];
}

#pragma mark - Core Data Saving support

- (void)saveContext {
    NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
    if (managedObjectContext != nil) {
        NSError *error = nil;
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
            // Replace this implementation with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog(@"Core Data Saving --- Unresolved error %@, %@", error, [error userInfo]);
            //            abort();
        }
    }
}
@end
