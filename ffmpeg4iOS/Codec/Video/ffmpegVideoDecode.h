//
//  ffmpegVideoDecode.h
//  ffmpeg4iOS
//
//  Created by Wayne W on 15/8/2.
//  Copyright (c) 2015年 github.com/henern. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "libavformat/avformat.h"
#import "YUVBuffer.h"

@interface DEF_CLASS(ffmpegVideoDecode) : NSObject

+ (BOOL)supportCodec:(AVCodecContext*)ctxCodec;

- (int)decodePacket:(AVPacket*)pkt                          // sync
          yuvBuffer:(id<DEF_CLASS(YUVBuffer)> *)yuvBuffer
              codec:(AVCodecContext*)ctxCodec
           finished:(int*)finished;

- (int)count4pendingYUVBuffers;

@end
