//
//  RenderBase+Factory.m
//  ffmpeg4iOS
//
//  Created by Wayne W on 15/7/19.
//  Copyright (c) 2015年 github.com/henern. All rights reserved.
//

#import "RenderBase+Factory.h"
#import "OpenGLRender.h"

@implementation DEF_CLASS(RenderBase) (Factory)

+ (instancetype)engine
{
    return [[DEF_CLASS(OpenGLRender) alloc] init];
}

+ (Class)renderLayerClass
{
    return [DEF_CLASS(OpenGLRender)  renderLayerClass];
}

@end
