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
    NSArray *sites = [NSArray arrayWithObjects:@"Konachan.com", @"Yande.re",nil];
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
//    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
//    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
    [[SDImageCache sharedImageCache] cleanDisk];
//           dispatch_async(dispatch_get_main_queue(), ^{
//               [MBProgressHUD hideHUDForView:self.view animated:YES];
               [self.clearCacheSwitcher setOn:NO];
               [self calculateCachedPicsSize];
//           });
//        }];
//    });
}

@end
