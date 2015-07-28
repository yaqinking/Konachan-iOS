//
//  TagGridViewController.m
//  Konachan
//
//  Created by 小笠原やきん on 15/7/28.
//  Copyright © 2015年 yaqinking. All rights reserved.
//

#import "TagPhotoBrowserViewController.h"
#import "SDImageCache.h"
#import "MWCommon.h"
#import "KonachanAPI.h"
#import "Tag.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import "Picture.h"

@implementation TagPhotoBrowserViewController


- (nullable instancetype)initWithCoder:(nonnull NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        self.title = self.tag.name;
        [[SDImageCache sharedImageCache] cleanDisk];
        [[SDImageCache sharedImageCache] clearMemory];
        
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.manager = [AFHTTPRequestOperationManager manager];
    
    self.photos = [[NSMutableArray alloc] init];
    self.thumbs = [[NSMutableArray alloc] init];
    
    self.delegate = self;
    self.startOnGrid = NO;
    self.enableGrid = YES;
    
    self.zoomPhotosToFill = YES;
    [self setCurrentPhotoIndex:0];
   
    self.pageOffset = 1;
    [self setupPhotosURLWithTag:@"loli" andPageoffset:self.pageOffset];
    NSLog(@"1 %i",self.pageOffset);
}



- (BOOL)shouldAutorotate {
    return YES;
}



- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (NSUInteger)numberOfPhotosInPhotoBrowser:(MWPhotoBrowser *)photoBrowser {
    return self.photos.count;
}

- (id <MWPhoto>)photoBrowser:(MWPhotoBrowser *)photoBrowser photoAtIndex:(NSUInteger)index {
    if (index < _photos.count)
        return [_photos objectAtIndex:index];
    return nil;
}

- (id <MWPhoto>)photoBrowser:(MWPhotoBrowser *)photoBrowser thumbPhotoAtIndex:(NSUInteger)index {
    if (index < _thumbs.count)
        return [_thumbs objectAtIndex:index];
    return nil;
}

- (void)photoBrowser:(MWPhotoBrowser *)photoBrowser didDisplayPhotoAtIndex:(NSUInteger)index {
    NSLog(@"Did start viewing photo at index %lu", (unsigned long)index);
    NSLog(@"当前正在看第 %lu 张图片",(unsigned long)index);
    if ((index + 1) > (self.photos.count * 0.7)) {
        
        NSLog(@"2 %i",self.pageOffset);
        self.pageOffset ++;
        NSLog(@"3 %i",self.pageOffset);
        [self setupPhotosURLWithTag:@"loli" andPageoffset:self.pageOffset];
        NSLog(@"4 %i",self.pageOffset);
        
    }
}

- (void)photoBrowserDidFinishModalPresentation:(MWPhotoBrowser *)photoBrowser {
    // If we subscribe to this method we must dismiss the view controller ourselves
    NSLog(@"Did finish modal presentation");
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)setupPhotosURLWithTag:(NSString *)tag andPageoffset:(int)pageOffset {
    
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat: KONACHAN_POST_LIMIT_PAGE_TAGS,@"10",pageOffset,tag]];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    NSLog(@"url %@",url);
    AFHTTPRequestOperation *op = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    op.responseSerializer = [AFJSONResponseSerializer serializer];
    [op setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        
        for (NSDictionary *picDict in responseObject) {
//                        NSLog(@" Dict -> %@",picDict);
            NSString *previewURLString = picDict[KONACHAN_DOWNLOAD_TYPE_PREVIEW];
            NSString *jpegURLString = picDict[KONACHAN_DOWNLOAD_TYPE_JPEG];
            
            Picture *thumbPic = [[Picture alloc] initWithURL:[NSURL URLWithString:previewURLString]];
            Picture *photoPic = [[Picture alloc] initWithURL:[NSURL URLWithString:jpegURLString]];
            [self.thumbs addObject:thumbPic];
            [self.photos addObject:photoPic];
        }
//        for (NSString *previewURL in self.photosURL) {
//            Picture *pic = [[Picture alloc] initWithURL:[NSURL URLWithString:previewURL]];
//
//            [self.photos addObject:pic];
//        }
        [self reloadData];
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"failure %@",error);
    }];
    [[NSOperationQueue mainQueue] addOperation:op];
}


@end
