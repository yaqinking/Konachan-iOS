//
//  TagStore.h
//  Konachan
//
//  Created by 小笠原やきん on 15/7/29.
//  Copyright © 2015年 yaqinking. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Tag;

@interface TagStore : NSObject

@property (nonatomic, readonly) NSArray *allTags;

+ (instancetype)sharedStore;
- (Tag *)createTag;
- (void)removeTag:(Tag *)tag;

- (BOOL)saveChanges;

@end
