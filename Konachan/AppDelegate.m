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
#import "KNCCoreDataStackManager.h"

@interface AppDelegate ()

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    [self configureSettings];
    [self congigureDynamicShortcutItems:(UIApplication *) application];
    [self configureKeyValueStore];
    [self configureDataMigration];
    return NO;
}

- (void)configureKeyValueStore {
    NSFileManager* fileManager = [NSFileManager defaultManager];
    id currentiCloudToken = fileManager.ubiquityIdentityToken;
    if (currentiCloudToken) {
        NSData *newTokenData =
        [NSKeyedArchiver archivedDataWithRootObject: currentiCloudToken];
        [[NSUserDefaults standardUserDefaults]
         setObject: newTokenData
         forKey: @"com.yaqinking.Konachan.UbiquityIdentityToken"];
    } else {
        [[NSUserDefaults standardUserDefaults]
         removeObjectForKey: @"com.yaqinking.Konachan.UbiquityIdentityToken"];
    }
}

- (void)congigureDynamicShortcutItems:(UIApplication *)application {
    NSArray *fetchedTags = [[KNCCoreDataStackManager sharedManager] savedTags ];
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
    [[KNCCoreDataStackManager sharedManager] saveContext];
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    [[KNCCoreDataStackManager sharedManager] saveContext];
}

#pragma mark - Configure Settings

- (void)configureSettings {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    
    [userDefaults registerDefaults:@{ kPreloadNextPage : @YES,
                                      kSwitchSite : @NO,
                                      kOfflineMode : @NO,
                                      kOpenBlacklist : @YES}];
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

- (void)configureDataMigration {
    NSArray<Tag *> *tags = [[KNCCoreDataStackManager sharedManager] savedTags];
    if (tags.count != 0) {
        [tags enumerateObjectsUsingBlock:^(Tag * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if (!obj.createDate) {
                obj.createDate = [NSDate new];
            }
        }];
        [[KNCCoreDataStackManager sharedManager] saveContext];
    }
}

@end
