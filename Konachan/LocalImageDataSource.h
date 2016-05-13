//
//  LocalImageDataSource.h
//  Konachan
//
//  Created by 小笠原やきん on 16/5/13.
//  Copyright © 2016年 yaqinking. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Image;
@class Tag;

@interface LocalImageDataSource : NSObject

- (NSDictionary *)imageDataDictionaryWithTag:(NSString *)tag;
- (void)insertImagesFromResonseObject:(id)responseObject;
- (void)clearImages;

@end
