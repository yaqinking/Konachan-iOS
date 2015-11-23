//
//  KonachanAPI.h
//  Konachan.com API
//  Created by yaqinking on 4/26/15.
//  Copyright (c) 2015 yaqinking. All rights reserved.
//


//Debug mode

#define IS_DEBUG_MODE 0

//Get Post

//get post with limit per page image and page number and tags
#define KONACHAN_POST_LIMIT_PAGE_TAGS @"http://konachan.com/post.json?limit=%@&page=%i&tags=%@"

//safe mode Konachan
#define KONACHAN_SAFE_MODE_POST_LIMIT_PAGE_TAGS @"http://konachan.com/post.json?limit=%@&page=%i&tags=%@+rating:s"

//yande.re
#define YANDERE_POST_LIMIT_PAGE_TAGS  @"https://yande.re/post.json?limit=%@&page=%i&tags=%@"

//Example
//Get saenai_heroine_no_sodatekata Perpage 10 images
//http://konachan.com/post.json?limit=10&page=1&tags=saenai_heroine_no_sodatekata
//Get saenai_heroine_no_sodatekata Perpage 20 images and Page number is 2
//http://konachan.com/post.json?limit=20&page=2&tags=saenai_heroine_no_sodatekata

//get 10 posted images default max=100 per page
#define KONACHAN_POST_LIMIT_DEFAULT      @"http://konachan.com/post.json?limit=10"

//get 10 posted images set you want display page number
#define KONACHAN_POST_LIMIT_DEFAULT_PAGE @"http://konachan.com/post.json?limit=10&page=%i"

//Download illustrate quality
#define KONACHAN_DOWNLOAD_TYPE_SAMPLE  @"sample_url"
#define KONACHAN_DOWNLOAD_TYPE_PREVIEW @"preview_url"
#define KONACHAN_DOWNLOAD_TYPE_FILE    @"file_url"
#define KONACHAN_DOWNLOAD_TYPE_JPEG    @"jpeg_url"

#define KONACHAN_KEY_TAGS @"tags"

#define FETCH_AMOUNT @"30"

#define kSourceSite   @"source_site"
#define kKonachanMain @"Konachan.com"
#define kKonachanSafe @"Konachan.net"
#define kYandere      @"Yande.re"

//Ratings
#define kRatingSafe         @"s"
#define kRatingQuestionable @"q"
#define kRatingExplicit     @"e"