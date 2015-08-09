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
#import "SyncCore.h"
#import "ThreadSafeDebug.h"

typedef enum
{
    AVSTREAM_ENGINE_STATUS_INIT         = 0x0000,
    AVSTREAM_ENGINE_STATUS_PREPARE      = 0x0001,
    AVSTREAM_ENGINE_STATUS_PLAYING      = 0x0002,
    
    // more?
    
    AVSTREAM_ENGINE_STATUS_ERROR        = 0x0800,
    
}AVSTREAM_ENGINE_STATUS;

#define AVSE_STATUS_IS_PREPARE()        (([self status] & AVSTREAM_ENGINE_STATUS_PREPARE) != 0)
#define AVSE_STATUS_IS_PLAYING()        (([self status] & AVSTREAM_ENGINE_STATUS_PLAYING) != 0)

#define AVSE_STATUS_UNSET(s)            (self.status &= ~(s))
#define AVSE_STATUS_SET(s)              (self.status |= (s))

@interface DEF_CLASS(AVStreamEngine) : THREADSAFE_DEBUG_CLASS

@property (nonatomic, assign) AVStream *ref_stream;
@property (nonatomic, assign) int index_stream;
@property (nonatomic, strong) REF_CLASS(AVPacketsQueue) pkt_queue;
@property (nonatomic, assign, readonly) AVCodecContext *ctx_codec;
@property (nonatomic, assign) AVCodec *ref_codec;
@property (nonatomic, weak) id<DEF_CLASS(SyncCore)> ref_synccore;
@property (nonatomic, assign) AVSTREAM_ENGINE_STATUS status;

- (double)time_base;

- (void)cleanup;

- (BOOL)attachTo:(AVStream*)stream err:(int*)errCode atIndex:(int)index;
- (BOOL)canHandlePacket:(AVPacket *)pkt;
- (BOOL)appendPacket:(AVPacket *)pkt;
- (BOOL)popPacket:(AVPacket*)destPkt;
- (AVPacket*)topPacket;

// queue is full, please wait for a while before push another packet
- (BOOL)isFull;
// current time of this stream
- (double)timestamp;
// adjust the delay according to the clock (sync-core)
- (double)delay4pts:(double)pts delayInPlan:(double)delay;

- (BOOL)reset;
- (BOOL)play;
- (BOOL)pause;
@end

// subclass MUST implement these
@interface DEF_CLASS(AVStreamEngine) (Sub)
- (BOOL)doPlay;
- (BOOL)doPause;
- (int)maxPacketQueued;
@end
