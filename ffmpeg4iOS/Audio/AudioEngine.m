//
//  AudioEngine.m
//  ffmpeg4iOS
//
//  Created by Wayne W. on 15/7/16.
//  Copyright (c) 2015年 github.com/henern. All rights reserved.
//

#import "AudioEngine.h"

@implementation DEF_CLASS(AudioEngine)

- (BOOL)appendPacket:(AVPacket *)pkt
{
    return [super appendPacket:pkt];
}

@end
