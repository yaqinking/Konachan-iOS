//
//  ViewController.h
//  Konachan
//
//  Created by 小笠原やきん on 15/7/25.
//  Copyright © 2015年 yaqinking. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MWPhotoBrowser.h"
#import "AFNetworking.h"

@interface ViewController : UIViewController<UITableViewDataSource, UITableViewDelegate, MWPhotoBrowserDelegate>
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (strong, nonatomic) NSMutableArray *tags;


@property (strong, nonatomic) NSMutableArray *photos;
@property (strong, nonatomic) NSMutableArray *thumbs;
@property (strong, nonatomic) NSMutableArray *photosURL;
@property (strong, nonatomic) NSMutableArray *thumbsURL;
@property (strong, nonatomic) NSString *pageOffset;
@property AFHTTPRequestOperationManager *manager;
@end

