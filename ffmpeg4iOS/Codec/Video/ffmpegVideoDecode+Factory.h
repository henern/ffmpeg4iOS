//
//  ffmpegVideoDecode+Factory.h
//  ffmpeg4iOS
//
//  Created by Wayne W on 15/8/2.
//  Copyright (c) 2015年 github.com/henern. All rights reserved.
//

#import "ffmpegVideoDecode.h"

@interface DEF_CLASS(ffmpegVideoDecode) (Factory)

+ (REF_CLASS(ffmpegVideoDecode))decoder4codec:(AVCodecContext*)ctxCodec;

@end
