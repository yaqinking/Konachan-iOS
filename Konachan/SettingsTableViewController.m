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
#import "KonachanAPI.h"
#define kSourceSite @"source_site"


@interface SettingsTableViewController ()

@property (weak, nonatomic) IBOutlet UITextField *fetchAmountTextField;
@property (weak, nonatomic) IBOutlet UILabel *loadThumbWayTextField;

@end

@implementation SettingsTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.title = @"Settings";
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self calculateCachedPicsSize];
    [self configureFetchAmount];
}

#pragma mark - Table View Delegate Methods

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSInteger row = indexPath.row;
    if (IS_DEBUG_MODE) {
        NSLog(@"Row %li",(long)row);
    }
    switch (row) {
        case 0:
            [self clearCache:self];
            [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
            break;
        case 1:
            [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
            break;
        case 2:
            [self switchThumbLoadWay:self];
            [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
            break;
        case 3:
            [self chooseSource:self];
            [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
            break;
        default:
            break;
    }
}

- (void)calculateCachedPicsSize {
    __weak typeof(self) weakSelf = self;
    [[SDImageCache sharedImageCache] calculateSizeWithCompletionBlock:^(NSUInteger fileCount, NSUInteger totalSize) {
        weakSelf.cachedSizeLabel.text = [NSString stringWithFormat:@"%.2f M", totalSize/1024.0/1024.0];
    }];
    
}

- (void)configureFetchAmount {
    NSInteger fetchAmount = [[NSUserDefaults standardUserDefaults] integerForKey:kFetchAmount];
    self.fetchAmountTextField.text = [NSString stringWithFormat:@"%lu",fetchAmount];
    
}

- (void)chooseSource:(id)sender {
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
               
           } origin:self.fetchAmountTextField];
    
}

- (void)switchThumbLoadWay:(id)sender {
    NSArray *loadWays = [NSArray arrayWithObjects:@"Load thumbs", @"Predownload pictures",nil];
    [ActionSheetStringPicker showPickerWithTitle:@"Switch Thumb Load Way"
                                            rows:loadWays
                                initialSelection:0
                                       doneBlock:^(ActionSheetStringPicker *picker, NSInteger selectedIndex, id selectedValue) {
                                           NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
                                           [defaults setValue:selectedValue forKey:kThumbLoadWay];
                                           [defaults synchronize];
                                       } cancelBlock:^(ActionSheetStringPicker *picker) {
                                           
                                       } origin:self.loadThumbWayTextField];
}



- (void)clearCache:(id)sender {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Do you want to clear image cache?" message:@"" preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK"
                                                        style:UIAlertActionStyleDefault
                                                      handler:^(UIAlertAction * _Nonnull action) {
                                                          SDImageCache *imageCache = [SDImageCache sharedImageCache];
                                                          [imageCache clearMemory];
                                                          [imageCache clearDiskOnCompletion:^{
                                                              [self calculateCachedPicsSize];
                                                          }];
                                                      }];
    
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel"
                                                           style:UIAlertActionStyleCancel
                                                         handler:^(UIAlertAction * _Nonnull action) {
                                                             
                                                         }];
    
    [alert addAction:okAction];
    [alert addAction:cancelAction];
    
    [self presentViewController:alert animated:YES completion:nil];
    
}

- (IBAction)setFetchAmount:(id)sender {
    NSInteger fetchAmount = [self.fetchAmountTextField.text integerValue];
    if (fetchAmount < [kFetchAmountDefault integerValue]) {
        [self showHUDWithTitle:@"Error >_<"
                       content:@"Min fetch amount is 30"];
        return;
    }
    if (IS_DEBUG_MODE) {
        if (fetchAmount == 512181) {
            [self showHUDWithTitle:@"Set source site"
                           content:@"Set to Konachan.com success!"];
            [self setSourceSiteTo:@"Konachan.com"];
        } else if (fetchAmount == 512182) {
            [self showHUDWithTitle:@"Set source site"
                           content:@"Set to yande.re success!"];
            [self setSourceSiteTo:@"Yande.re"];
        }
    }
    if (fetchAmount > 100) {
        [self showHUDWithTitle:@"Error >_<"
                       content:@"Max fetch amount is 100"];
    } else {
        [[NSUserDefaults standardUserDefaults] setInteger:fetchAmount forKey:kFetchAmount];
//        NSLog(@"Set amount success %lu", fetchAmount);
        [self showHUDWithTitle:@"Success!" content:[NSString stringWithFormat:@"Set fetch amount to %li success!",(long)fetchAmount]];
    }
}

- (void) setSourceSiteTo:(NSString *) site {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setValue:site forKey:kSourceSite];
    [defaults synchronize];
}

- (void) showHUDWithTitle:(NSString *)title content:(NSString *)content {
    [self dismissNumberPadKeyboard];
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.labelText = title;
    hud.detailsLabelText = content;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [MBProgressHUD hideHUDForView:self.view animated:YES];
    });
    [self configureFetchAmount];
}

- (void) dismissNumberPadKeyboard {
    [self.fetchAmountTextField resignFirstResponder];
}

@end
