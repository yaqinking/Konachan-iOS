//
//  Tag.h
//  Konachan
//
//  Created by 小笠原やきん on 15/7/26.
//  Copyright © 2015年 yaqinking. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Tag : NSObject

@property (strong, nonatomic) NSString *name;//tag name such as loli
@property (unsafe_unretained ,nonatomic) NSURL *previewImageURL;//table view cell image url only return one image.


@end
