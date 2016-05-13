//
//  Image+CoreDataProperties.h
//  Konachan
//
//  Created by 小笠原やきん on 16/5/12.
//  Copyright © 2016年 yaqinking. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "Image.h"

NS_ASSUME_NONNULL_BEGIN

@interface Image (CoreDataProperties)

@property (nullable, nonatomic, retain) NSNumber *create_at;
@property (nullable, nonatomic, retain) NSString *file_url;
@property (nullable, nonatomic, retain) NSString *jpeg_url;
@property (nullable, nonatomic, retain) NSString *md5;
@property (nullable, nonatomic, retain) NSString *preview_url;
@property (nullable, nonatomic, retain) NSString *rating;
@property (nullable, nonatomic, retain) NSString *sample_url;
@property (nullable, nonatomic, retain) NSString *tags;
@property (nullable, nonatomic, retain) NSString *site;
@property (nullable, nonatomic, retain) NSNumber *image_id;

@end

NS_ASSUME_NONNULL_END
