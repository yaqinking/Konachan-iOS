//
//  AppDelegate.m
//  Konachan
//
//  Created by 小笠原やきん on 15/8/5.
//  Copyright © 2015年 yaqinking. All rights reserved.
//

#import "AppDelegate.h"
#import "KonachanAPI.h"
#import "ViewController.h"
#import "Tag.h"



@interface AppDelegate ()

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    [self configureSettings];
    [self congigureDynamicShortcutItems:(UIApplication *) application];
    return NO;
}

- (void)congigureDynamicShortcutItems:(UIApplication *)application {
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Tag"];
    NSArray *fetchedTags = [self.managedObjectContext executeFetchRequest:request error:NULL];
    if (fetchedTags.count > 1) {
        Tag *lastTag = [fetchedTags lastObject];
        Tag *secondTag = [fetchedTags objectAtIndex:(fetchedTags.count-2)];
        NSString *lastKeyword = lastTag.name;
        NSString *secondKeyword = secondTag.name;
        UIMutableApplicationShortcutItem *lastItem = [[UIMutableApplicationShortcutItem alloc] initWithType:KonachanShortcutItemViewLast
                                                                                             localizedTitle:[NSString stringWithFormat:@"View %@", lastKeyword]];
        UIMutableApplicationShortcutItem *secondItem = [[UIMutableApplicationShortcutItem alloc] initWithType:KonachanShortcutItemViewSecond localizedTitle:[NSString stringWithFormat:@"View %@", secondKeyword]];
        application.shortcutItems = @[secondItem, lastItem];
    } else if (fetchedTags.count == 1){
        Tag *lastTag = [fetchedTags lastObject];
        NSString *lastKeyword = lastTag.name;
        UIMutableApplicationShortcutItem *lastItem = [[UIMutableApplicationShortcutItem alloc] initWithType:KonachanShortcutItemViewLast
                                                                                             localizedTitle:[NSString stringWithFormat:@"View %@", lastKeyword]];
        application.shortcutItems = @[lastItem];
    } else {
        application.shortcutItems = nil;
    }
}


- (void)application:(UIApplication *)application performActionForShortcutItem:(UIApplicationShortcutItem *)shortcutItem completionHandler:(void (^)(BOOL))completionHandler {
    
    NSString *shortcutItemType = shortcutItem.type;
    NSArray *viewControllers = ((UINavigationController *)self.window.rootViewController).viewControllers;
    ViewController *viewController = viewControllers[0];
    [self popToRootViewController];
    
    if ([shortcutItemType isEqualToString:KonachanShortcutItemAddKeyword]) {
        [viewController addTag:nil];
    } else {
        [viewController performSegueWithIdentifier:KonachanSegueIdentifierShowTagPhotos sender:shortcutItemType];
    }
}

- (void)popToRootViewController {
    UINavigationController *navigationViewController = (UINavigationController *)self.window.rootViewController;
    [navigationViewController popToRootViewControllerAnimated:NO];
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    [self congigureDynamicShortcutItems:application];
    [self saveContext];
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    [self saveContext];
}

#pragma mark - Core Data stack

@synthesize managedObjectContext = _managedObjectContext;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;

NSString *const ErrorDomain = @"yaqinking.moe";
NSString *const ContentNameKey = @"moe~yaqinking~konachan";
NSString *const ApplicationDocumentsDirectoryName = @"konachan.sqlite";

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
    NSDictionary *storeOptions = @{NSPersistentStoreUbiquitousContentNameKey: ContentNameKey};
    NSError *error = nil;
    NSString *failureReason = @"There was an error creating or loading the application's saved data.";
    NSPersistentStore *store = nil;
    if (! (store = [ _persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:storeOptions error:&error])) {
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
    
    if (IS_DEBUG_MODE) {
        NSURL *finaliCloudURL = [store URL];
        NSLog(@"finaliCloudURL: %@", finaliCloudURL);
    }
    return _persistentStoreCoordinator;
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

#pragma mark - Configure Settings

- (void)configureSettings {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    
    [userDefaults registerDefaults:@{ kPreloadNextPage : @YES,
                                      kSwitchSite : @NO}];
    NSInteger fetchAmount = [userDefaults integerForKey:kFetchAmount];
    if ((fetchAmount == 0 && iPadProPortrait) || (fetchAmount == 0 && iPadProLandscape)) {
//        NSLog(@"iPad Pro");
        [userDefaults setInteger:kFetchAmountiPadProMin forKey:kFetchAmount];
    } else if (fetchAmount == 0 && iPad) {
//        NSLog(@"iPad Retina");
        //iPad need load more pictures in order to get pull up to load more pictures.
        [userDefaults setInteger:kFetchAmountDefault forKey:kFetchAmount];
    } else if (fetchAmount == 0 && iPhone) {
        [userDefaults setInteger:kFetchAmountMin forKey:kFetchAmount];
    }
    
    NSInteger thumbLoadWay = [userDefaults integerForKey:kThumbLoadWay];
    NSInteger downloadImageType = [userDefaults integerForKey:kDownloadImageType];
    if (thumbLoadWay == KonachanPreviewImageLoadTypeUnseted) {
        [userDefaults setInteger:KonachanPreviewImageLoadTypeLoadPreview forKey:kThumbLoadWay];
    }
    if (downloadImageType == KonachanImageDownloadTypeUnseted) {
        [userDefaults setInteger:KonachanImageDownloadTypeSample forKey:kDownloadImageType];
    }
    [userDefaults synchronize];
    
}

@end
