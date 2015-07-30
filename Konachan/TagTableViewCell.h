//
//  TagTableViewCell.h
//  Konachan
//
//  Created by 小笠原やきん on 15/7/30.
//  Copyright © 2015年 yaqinking. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TagTableViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UIImageView *tagImageView;
@property (weak, nonatomic) IBOutlet UILabel *tagTextLabel;

@end
