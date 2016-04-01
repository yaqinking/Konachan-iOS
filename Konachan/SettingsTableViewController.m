//
//  SettingsTableViewController.m
//  Konachan
//
//  Created by 小笠原やきん on 15/8/9.
//  Copyright © 2015年 yaqinking. All rights reserved.
//

#import "SettingsTableViewController.h"
#import <SDWebImage/SDImageCache.h>
#import <SDWebImage/SDWebImageManager.h>
#import "MBProgressHUD.h"
#import "KonachanAPI.h"
#define kSourceSite @"source_site"


@interface SettingsTableViewController ()

@property (weak, nonatomic) IBOutlet UITextField *fetchAmountTextField;
@property (weak, nonatomic) IBOutlet UILabel *loadThumbWayTextField;
@property (weak, nonatomic) IBOutlet UILabel *downloadImageTypeLabel;
@property (weak, nonatomic) IBOutlet UILabel *sourceSiteLabel;
@property (weak, nonatomic) IBOutlet UISwitch *preloadNextPageSwitch;


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
    [self configurePreloadNextPage];
}

#pragma mark - Table View Delegate Methods

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSInteger row = indexPath.row;
    if (IS_DEBUG_MODE) {
        NSLog(@"Row %li",(long)row);
    }
    switch (indexPath.section) {
        case 0:
            switch (row) {
                case 0:
                    [self clearCache:self];
                    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
                    break;
                case 1:
                    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
                    break;
                case 2:
                    [self changePreviewImageType];
                    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
                    break;
                case 3:
                    [self changeDownloadImageType];
                    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
                    break;
                case 4:
                    [self changeSourceSite];
                    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
                    break;
                default:
                    break;
            }
            break;
        case 1:
            switch (row) {
                case 0:
                    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
                    break;
                default:
                    break;
            }
        default:
            break;
    }
    
}

- (void)changePreviewImageType {
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Change Preview Image Type"
                                                                   message:@""
                                                            preferredStyle:UIAlertControllerStyleActionSheet];
    
    UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel
                                                          handler:^(UIAlertAction * action) {}];
    UIAlertAction *loadPreviewImageAction = [UIAlertAction actionWithTitle:@"Load thumbs" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self writeConfigWith:KonachanPreviewImageLoadTypeLoadPreview andKey:kThumbLoadWay];
    }];
    UIAlertAction *loadDownloadImageAction = [UIAlertAction actionWithTitle:@"Predownload pictures" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self writeConfigWith:KonachanPreviewImageLoadTypeLoadDownloaded andKey:kThumbLoadWay];
    }];
    
    [alert addAction:loadPreviewImageAction];
    [alert addAction:loadDownloadImageAction];
    [alert addAction:defaultAction];
    
    [self popoverPresentWith:alert To:self.loadThumbWayTextField];
    [self presentViewController:alert animated:YES completion:nil];

}

- (void)popoverPresentWith:(UIAlertController *)alert To:(UILabel *) sender {
    [alert setModalPresentationStyle:UIModalPresentationPopover];
    UIPopoverPresentationController *popPresenter = [alert popoverPresentationController];
    popPresenter.sourceView = sender;
    popPresenter.sourceRect = sender.bounds;
}

- (void)changeDownloadImageType {
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Change Download Image Type"
                                                                   message:@""
                                                            preferredStyle:UIAlertControllerStyleActionSheet];
    
    UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel
                                                          handler:^(UIAlertAction * action) {}];
    UIAlertAction *loadSampleImageAction = [UIAlertAction actionWithTitle:@"Sample" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self writeConfigWith:KonachanImageDownloadTypeSample andKey:kDownloadImageType];
    }];
    UIAlertAction *loadJPEGImageAction = [UIAlertAction actionWithTitle:@"JPEG" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self writeConfigWith:KonachanImageDownloadTypeJPEG andKey:kDownloadImageType];
    }];
    UIAlertAction *loadFileImageAction = [UIAlertAction actionWithTitle:@"Original" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self writeConfigWith:KonachanImageDownloadTypeFile andKey:kDownloadImageType];
    }];
    [alert addAction:loadSampleImageAction];
    [alert addAction:loadJPEGImageAction];
    [alert addAction:loadFileImageAction];
    [alert addAction:defaultAction];
    
    [self popoverPresentWith:alert To:self.downloadImageTypeLabel];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)changeSourceSite {
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Set Source Site To"
                                                                   message:@""
                                                            preferredStyle:UIAlertControllerStyleActionSheet];
    
    UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel
                                                          handler:^(UIAlertAction * action) {}];
    UIAlertAction *konachanAction = [UIAlertAction actionWithTitle:@"Konachan.com" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self writeConfigWith:KonachanSourceSiteTypeKonachan_com andKey:kSourceSite];
    }];
    UIAlertAction *konachanSafeModeAction = [UIAlertAction actionWithTitle:@"Konachan.net" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self writeConfigWith:KonachanSourceSiteTypeKonachan_net andKey:kSourceSite];
    }];
    UIAlertAction *yandereAction = [UIAlertAction actionWithTitle:@"Yande.re" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self writeConfigWith:KonachanSourceSiteTypeYande_re andKey:kSourceSite];
    }];
    
    [alert addAction:konachanAction];
    [alert addAction:konachanSafeModeAction];
    [alert addAction:yandereAction];
    [alert addAction:defaultAction];
    
    [self popoverPresentWith:alert To:self.sourceSiteLabel];
    [self presentViewController:alert animated:YES completion:nil];
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

- (void)configurePreloadNextPage {
    BOOL isPreloadNextPage = [[NSUserDefaults standardUserDefaults] boolForKey:kPreloadNextPage];
    self.preloadNextPageSwitch.on = isPreloadNextPage;
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
    
    if ((fetchAmount < kFetchAmountiPadProMin && iPadProPortrait) ||
        (fetchAmount < kFetchAmountiPadProMin && iPadProLandscape)) {
        [self showHUDWithTitle:@"Error >_<"
                       content:@"iPad Pro Min fetch amount is 56"];
        return;
    }
    if (fetchAmount < kFetchAmountDefault && iPad) {
        [self showHUDWithTitle:@"Error >_<"
                       content:@"iPad Min fetch amount is 40"];
        return;
    }
    if (fetchAmount < kFetchAmountMin && iPhone) {
        [self showHUDWithTitle:@"Error >_<"
                       content:@"Min fetch amount is 30"];
        return;
    }
    if (IS_DEBUG_MODE) {
        if (fetchAmount == 512181) {
            [self showHUDWithTitle:@"Set source site"
                           content:@"Set to Konachan.com success!"];
            [self writeConfigWith:KonachanSourceSiteTypeKonachan_com andKey:kSourceSite];
        } else if (fetchAmount == 512182) {
            [self showHUDWithTitle:@"Set source site"
                           content:@"Set to yande.re success!"];
            [self writeConfigWith:KonachanSourceSiteTypeYande_re andKey:kSourceSite];
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

- (IBAction)changePreloadNextPageImage:(UISwitch *)sender {
    if (sender.on) {
        [self writeConfigWith:1 andKey:kPreloadNextPage];
    } else {
        [self writeConfigWith:0 andKey:kPreloadNextPage];
    }
}


- (void) writeConfigWith:(NSInteger) value andKey:(NSString *)key{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setInteger:value forKey:key];
    [defaults synchronize];
}

- (void) write {
    
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
