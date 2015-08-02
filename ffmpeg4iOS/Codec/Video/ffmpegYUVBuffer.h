//
//  ffmpegYUVBuffer.h
//  ffmpeg4iOS
//
//  Created by Wayne W on 15/8/2.
//  Copyright (c) 2015年 github.com/henern. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "YUVBuffer.h"

@interface DEF_CLASS(ffmpegYUV420PBuffer) : NSObject <DEF_CLASS(YUVBuffer)>

// buffer is bind to the codec
- (instancetype)initWithCodec:(AVCodecContext*)ctxCodec;

// keep a buffer of decoded frame
- (BOOL)attach2frame:(AVFrame*)avfDecoded fmt:(enum AVPixelFormat)fmt;

@end
