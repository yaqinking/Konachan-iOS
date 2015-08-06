//
//  PhotoCell.m
//  Konachan
//
//  Created by 小笠原やきん on 15/8/5.
//  Copyright © 2015年 yaqinking. All rights reserved.
//

#import "PhotoCell.h"

@implementation PhotoCell

- (void)layoutSubviews {
    [super layoutSubviews];
    [self performLayout];
}

- (void)performLayout {
    CGSize imageSize = self.image.image.size;
    NSLog(@"width  %f height %f ", imageSize.width, imageSize.height);
//    self.bounds = CGRectMake(0, 0, imageSize.width * 0.1, imageSize.width * 0.1);
}


@end
