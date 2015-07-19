//
//  RenderBase+Factory.h
//  ffmpeg4iOS
//
//  Created by Wayne W on 15/7/19.
//  Copyright (c) 2015年 github.com/henern. All rights reserved.
//

#import "RenderBase.h"

@interface DEF_CLASS(RenderBase) (Factory)

+ (instancetype)engine;
+ (Class)renderLayerClass;

@end
