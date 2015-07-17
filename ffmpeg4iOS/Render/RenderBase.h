//
//  RenderBase.h
//  ffmpeg4iOS
//
//  Created by Wayne W. on 15/7/16.
//  Copyright (c) 2015年 github.com/henern. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AVStreamEngine.h"

@interface DEF_CLASS(RenderBase) : DEF_CLASS(AVStreamEngine)

@property (nonatomic, assign) float aspectRatio;
@property (nonatomic, assign) CGRect bounds;

@end
