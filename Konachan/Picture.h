//
//  Picture.h
//  Konachan
//
//  Created by 小笠原やきん on 15/7/26.
//  Copyright © 2015年 yaqinking. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MWPhoto.h"

@interface Picture : MWPhoto

@property (strong, nonatomic) NSString *name;
@property (nonatomic, unsafe_unretained) NSURL *previewURL;//As thumb
@property (nonatomic, unsafe_unretained) NSURL *jpegURL;//As iPad
@property (nonatomic, unsafe_unretained) NSURL *fileURL;// If didn't have jpegURL it will be never used.
@property (nonatomic, unsafe_unretained) NSURL *sampleURL;//As iphone

@end
