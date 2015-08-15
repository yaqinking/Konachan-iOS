//
//  ViewController.h
//  Konachan
//
//  Created by 小笠原やきん on 15/7/25.
//  Copyright © 2015年 yaqinking. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UITableViewController

@property (strong, nonatomic) NSArray *previewImageURLs;
@property (strong, nonatomic) NSString *sourceSite;


- (IBAction)addTag:(id)sender;


@end

