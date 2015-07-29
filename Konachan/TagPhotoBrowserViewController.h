//
//  TagGridViewController.h
//  Konachan
//
//  Created by 小笠原やきん on 15/7/28.
//  Copyright © 2015年 yaqinking. All rights reserved.
//

#import "AFNetworking.h"
#import "MWPhotoBrowser.h"
#import "Tag.h"

@interface TagPhotoBrowserViewController : MWPhotoBrowser<MWPhotoBrowserDelegate>

@property (strong, nonatomic) Tag *tag;

@property (strong, nonatomic) NSMutableArray *photos;
@property (strong, nonatomic) NSMutableArray *thumbs;
@property (nonatomic) int pageOffset;


@property AFHTTPRequestOperationManager *manager;


@end
