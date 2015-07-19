//
//  AVStreamEngine.h
//  ffmpeg4iOS
//
//  Created by Wayne W. on 15/7/17.
//  Copyright (c) 2015年 github.com/henern. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AVPacketsQueue.h"
#import "libavformat/avformat.h"

@interface DEF_CLASS(AVStreamEngine) : NSObject

@property (nonatomic, assign) AVStream *ref_stream;
@property (nonatomic, assign) int index_stream;
@property (nonatomic, strong) REF_CLASS(AVPacketsQueue) pkt_queue;
@property (nonatomic, assign, readonly) AVCodecContext *ctx_codec;
@property (nonatomic, assign) AVCodec *ref_codec;

- (void)cleanup;

- (BOOL)attachTo:(AVStream*)stream err:(int*)errCode atIndex:(int)index;
- (BOOL)canHandlePacket:(AVPacket *)pkt;
- (BOOL)appendPacket:(AVPacket *)pkt;
- (BOOL)popPacket:(AVPacket*)destPkt;
- (AVPacket*)topPacket;

- (BOOL)reset;

@end
