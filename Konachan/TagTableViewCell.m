//
//  TagTableViewCell.m
//  Konachan
//
//  Created by 小笠原やきん on 15/7/30.
//  Copyright © 2015年 yaqinking. All rights reserved.
//

#import "TagTableViewCell.h"

@implementation TagTableViewCell

- (void)awakeFromNib {
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.tagImageView.contentMode = UIViewContentModeScaleAspectFit;
    CGRect cellBounds = self.bounds;
    self.tagImageView.frame = CGRectMake(cellBounds.origin.x + 10,
                                      cellBounds.origin.y + 5, 75, 50);
    
    self.tagTextLabel.frame = CGRectMake(cellBounds.origin.x + 90, cellBounds.origin.y + 5 , self.textLabel.frame.size.width,50);
    
    CGFloat red = 33.0;
    CGFloat green = 33.0;
    CGFloat blue = 33.0;
    CGFloat alpha = 255.0;
    UIColor *color = [UIColor colorWithRed:(red/255.0) green:(green/255.0) blue:(blue/255.0) alpha:(alpha/255.0)];
    self.backgroundColor = color;
    self.textLabel.textColor = [UIColor whiteColor];

}


@end
