//
//  RenderBase.h
//  ffmpeg4iOS
//
//  Created by Wayne W. on 15/7/16.
//  Copyright (c) 2015年 github.com/henern. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "libavformat/avformat.h"

@interface DEF_CLASS(RenderBase) : NSObject

@property (nonatomic, assign) float aspectRatio;
@property (nonatomic, assign) CGRect bounds;

- (BOOL)attachTo:(AVStream*)stream err:(int*)errCode;

@end
