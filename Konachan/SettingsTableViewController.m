//
//  SettingsTableViewController.m
//  Konachan
//
//  Created by 小笠原やきん on 15/8/9.
//  Copyright © 2015年 yaqinking. All rights reserved.
//

#import "SettingsTableViewController.h"
#import "ActionSheetPicker.h"
#import <SDWebImage/SDImageCache.h>
#import <SDWebImage/SDWebImageManager.h>
#import "MBProgressHUD.h"

#define kSourceSite @"source_site"


@interface SettingsTableViewController ()



@end

@implementation SettingsTableViewController

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self calculateCachedPicsSize];
    
}

- (void)calculateCachedPicsSize {
    __weak typeof(self) weakSelf = self;
    [[SDImageCache sharedImageCache] calculateSizeWithCompletionBlock:^(NSUInteger fileCount, NSUInteger totalSize) {
        weakSelf.cachedSizeLabel.text = [NSString stringWithFormat:@"%.2f M", totalSize/1024.0/1024.0];
    }];
    
}

- (IBAction)chooseSource:(UIButton *)sender {
    NSArray *sites = [NSArray arrayWithObjects:@"Konachan.com", @"Konachan.net", @"Yande.re",nil];
    [ActionSheetStringPicker showPickerWithTitle:@"Source site"
                                            rows:sites
                                initialSelection:0
           doneBlock:^(ActionSheetStringPicker *picker, NSInteger selectedIndex, id selectedValue) {
//               NSLog(@"%@",selectedValue);
               NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
               [defaults setValue:selectedValue forKey:kSourceSite];
               if ([defaults synchronize]) {
//                   NSLog(@"default write succes %@",selectedValue);
               }
           } cancelBlock:^(ActionSheetStringPicker *picker) {
               
           } origin:sender];
    
}

- (IBAction)clearCache:(id)sender {
    SDImageCache *imageCache = [SDImageCache sharedImageCache];
    [imageCache clearMemory];
    [imageCache clearDiskOnCompletion:^{
        [self.clearCacheSwitcher setOn:NO];
        [self calculateCachedPicsSize];
    }];
    
}

@end
