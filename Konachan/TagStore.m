//
//  TagStore.m
//  Konachan
//
//  Created by 小笠原やきん on 15/7/29.
//  Copyright © 2015年 yaqinking. All rights reserved.
//

#import "TagStore.h"
#import "Tag.h"

@interface TagStore ()

@property (nonatomic) NSMutableArray *privateTags;

@end

@implementation TagStore

/**
 *  Create a singleton that is thread-safe by using dispatch_once to ensure that code is run exactly once.
 *
 *  @return
 */
+ (instancetype)sharedStore {
    static TagStore *sharedStore;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedStore = [[self alloc] initPrivate];
    });
    
    return sharedStore;
}

/**
 *  這個異常拋的好，是在下輸了。
 *
 *  @return
 */
- (instancetype)init {
    @throw [NSException exceptionWithName:@"Singleton"
                                   reason:@"Use +[TagStore sharedStore]"
                                 userInfo:nil];
    return nil;
}

- (instancetype)initPrivate {
    self = [super init];
    if (self) {
        NSString *path = [self tagArchivePath];
        self.privateTags = [NSKeyedUnarchiver unarchiveObjectWithFile:path];
        if (!self.privateTags) {
            self.privateTags = [[NSMutableArray alloc] init];
//            NSArray *tagsArrary = @[@"loli",@"2girls",@"skirt"];
//            for (int i = 0 ; i < 3; i++) {
//                Tag *tag = [self createTag];
//                tag.name = tagsArrary[i];
//                NSLog(@"TagStore -> %@",tag.name);
//            }

        }
        
    }
    return self;
}

- (NSString *)tagArchivePath {
    NSArray *documentDirectories = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentDirectory = [documentDirectories firstObject];
    return [documentDirectory stringByAppendingPathComponent:@"tags.archive"];
}

- (BOOL)saveChanges {
    NSString *path = [self tagArchivePath];
//    NSLog(@"save %lul tags",(unsigned long)[self.privateTags count]);
    return [NSKeyedArchiver archiveRootObject:self.privateTags toFile:path];
}

- (NSArray *)allTags {
    return [self.privateTags copy];
}

- (Tag *)createTag {
    Tag *tag = [[Tag alloc] init];
    [self.privateTags addObject:tag];
    return tag;
}

- (void)removeTag:(Tag *)tag {
    [self.privateTags removeObjectIdenticalTo:tag];
}


@end
