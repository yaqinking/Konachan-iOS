//
//  Tag+CoreDataProperties.h
//  Konachan
//
//  Created by 小笠原やきん on 16/5/12.
//  Copyright © 2016年 yaqinking. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "Tag.h"

NS_ASSUME_NONNULL_BEGIN

@interface Tag (CoreDataProperties)

@property (nullable, nonatomic, retain) NSString *name;
@property (nullable, nonatomic, retain) NSDate *createDate;

@end

NS_ASSUME_NONNULL_END
