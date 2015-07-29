//
//  Tag.m
//  Konachan
//
//  Created by 小笠原やきん on 15/7/26.
//  Copyright © 2015年 yaqinking. All rights reserved.
//

#import "Tag.h"

@implementation Tag

- (nullable instancetype)initWithCoder:(nonnull NSCoder *)aDecoder {
    self = [super init];
    if (self) {
        self.name = [aDecoder decodeObjectForKey:@"name"];
    }
    return self;
}

- (void)encodeWithCoder:(nonnull NSCoder *)aCoder {
    [aCoder encodeObject:self.name forKey:@"name"];
}



@end
