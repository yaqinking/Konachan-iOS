//
//  PreloadPhotoManager.h
//  Konachan
//
//  Created by 小笠原やきん on 4/1/16.
//  Copyright © 2016 yaqinking. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PreloadPhotoManager : NSObject

+ (PreloadPhotoManager *)manager;

- (void)GET:(NSString *)url;

@end
