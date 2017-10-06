//
//  NSString+URL.m
//  Konachan
//
//  Created by yaqinking on 2017/10/6.
//  Copyright © 2017年 yaqinking. All rights reserved.
//

#import "NSString+URL.h"

@implementation NSString_URL

+(NSString *)appendHttpsIfNeeded:(NSString *)url {
    if (![[url substringToIndex:4] isEqualToString:@"http"]) {
        url = [NSString stringWithFormat:@"https:%@", url];
    }
    return url;
}

@end
