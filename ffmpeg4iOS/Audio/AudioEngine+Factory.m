//
//  AudioEngine+Factory.m
//  ffmpeg4iOS
//
//  Created by Wayne W on 15/7/19.
//  Copyright (c) 2015年 github.com/henern. All rights reserved.
//

#import "AudioEngine+Factory.h"
#import "AudioToolBoxEngine.h"

@implementation DEF_CLASS(AudioEngine) (Factory)

+ (instancetype)engine
{
    return [[DEF_CLASS(AudioToolBoxEngine) alloc] init];
}

@end
