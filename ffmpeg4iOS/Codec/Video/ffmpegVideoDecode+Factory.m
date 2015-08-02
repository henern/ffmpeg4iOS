//
//  ffmpegVideoDecode+Factory.m
//  ffmpeg4iOS
//
//  Created by Wayne W on 15/8/2.
//  Copyright (c) 2015年 github.com/henern. All rights reserved.
//

#import "ffmpegVideoDecode+Factory.h"
#import "ffmpegVideoDecode.h"
#import <UIKit/UIKit.h>
#import "Utility.h"

@implementation DEF_CLASS(ffmpegVideoDecode) (Factory)

+ (REF_CLASS(ffmpegVideoDecode))decoder4codec:(AVCodecContext*)ctxCodec
{
    if (IOS8_OR_LATER() && ctxCodec->codec_id == AV_CODEC_ID_H264)
    {
        // FIXME: pick up VTB-decoder
    }
    
    return [[DEF_CLASS(ffmpegVideoDecode) alloc] init];
}

@end
