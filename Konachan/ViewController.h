//
//  ViewController.h
//  Konachan
//
//  Created by 小笠原やきん on 15/7/25.
//  Copyright © 2015年 yaqinking. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AFNetworking.h"

@interface ViewController : UITableViewController

@property (strong, nonatomic) NSArray *tags;
@property (strong, nonatomic) NSMutableArray *previewImageURLs;

@property AFHTTPRequestOperationManager *manager;


@end

