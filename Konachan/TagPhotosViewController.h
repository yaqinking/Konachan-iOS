//
//  TagPhotosViewController.h
//  Konachan
//
//  Created by 小笠原やきん on 15/8/5.
//  Copyright © 2015年 yaqinking. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MWPhotoBrowser.h"

@class Tag;

@interface TagPhotosViewController : UICollectionViewController<MWPhotoBrowserDelegate, UICollectionViewDelegateFlowLayout>

@property (strong, nonatomic) NSMutableArray *photos;
@property (strong, nonatomic) NSMutableArray *thumbs;
@property (strong, nonatomic) NSMutableArray *photosURL;
@property (strong, nonatomic) Tag *tag;
@property (nonatomic) int pageOffset;
@property (nonatomic) BOOL isInfiniting;
@end
