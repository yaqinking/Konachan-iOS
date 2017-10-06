//
//  NSString+URL.h
//  Konachan
//
//  Created by yaqinking on 2017/10/6.
//  Copyright © 2017年 yaqinking. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString_URL : NSString

+ (NSString *)appendHttpsIfNeeded: (NSString *)url ;

@end
