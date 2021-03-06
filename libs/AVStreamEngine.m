//
//  AVStreamEngine.m
//  ffmpeg4iOS
//
//  Created by Wayne W. on 15/7/17.
//  Copyright (c) 2015年 github.com/henern. All rights reserved.
//

#import "AVStreamEngine.h"
#import "ehm.h"

@interface DEF_CLASS(AVStreamEngine) ()
{
    AVCodecContext *m_ctx_codec;        // owned
}
@end

@implementation DEF_CLASS(AVStreamEngine)

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        self.pkt_queue = [[DEF_CLASS(AVPacketsQueue) alloc] init];
    }
    
    return self;
}

- (void)dealloc
{
    [self cleanup];
    FFMLOG_OC(@"%@ already destroyed.", [self class]);
}

- (void)cleanup
{
    VHOSTTHREAD();
    
    self.status = AVSTREAM_ENGINE_STATUS_INIT;
    [self.pkt_queue cleanup];
    
    AVCodecContext *ctx = m_ctx_codec;
    m_ctx_codec = NULL;
    if (ctx)
    {
        avcodec_free_context(&ctx);
    }
    
    self.ref_stream = NULL;
    self.index_stream = 0;
    self.ref_codec = NULL;
}

- (BOOL)reset
{
    VHOSTTHREAD();
    
    self.status = AVSTREAM_ENGINE_STATUS_INIT;
    AVSE_STATUS_SET(AVSTREAM_ENGINE_STATUS_PREPARE);
    
    [self.pkt_queue reset];
    avcodec_flush_buffers([self ctx_codec]);
    
    return YES;
}

- (BOOL)play
{
    VHOSTTHREAD();
    
    BOOL ret = YES;
    
    if (!AVSE_STATUS_IS_PLAYING())
    {
        ret = [self doPlay];
        CBR(ret);
        
        AVSE_STATUS_SET(AVSTREAM_ENGINE_STATUS_PLAYING);
    }
    
ERROR:
    return ret;
}

- (BOOL)pause
{
    VHOSTTHREAD();
    
    BOOL ret = YES;
    
    if (AVSE_STATUS_IS_PLAYING())
    {
        ret = [self doPause];
        CBRA(ret);
        
        AVSE_STATUS_UNSET(AVSTREAM_ENGINE_STATUS_PLAYING);
    }
    
ERROR:
    return ret;
}

- (BOOL)attachTo:(AVStream*)stream err:(int*)errCode atIndex:(int)index
{
    VHOSTTHREAD();
    
    BOOL ret = YES;
    int err = ERR_SUCCESS;
    AVCodecContext *enc = NULL;
    AVCodec *codec = NULL;
    AVCodecContext *ctx4codec = NULL;
    
    [self cleanup];
    
    // update status
    AVSE_STATUS_SET(AVSTREAM_ENGINE_STATUS_PREPARE);
    
    // mode for discard
    stream->discard = AVDISCARD_NONE;   // AVDISCARD_DEFAULT
    
    // codec
    enc = stream->codec;
    CPRA(enc);
    
    codec = avcodec_find_decoder(enc->codec_id);
    CPRA(codec);
    
    // MUST copy the ctx! check avcodec_open2
    ctx4codec = avcodec_alloc_context3(codec);
    CPRA(ctx4codec);
    err = avcodec_copy_context(ctx4codec, enc);
    CBRA(err == ERR_SUCCESS);
    UNUSE(enc);
    
    err = avcodec_open2(ctx4codec, codec, NULL);
    CBRA(err >= ERR_SUCCESS);
    
    // keep ref
    self.ref_codec = codec;     // assign
    m_ctx_codec = ctx4codec;    // owned!
    ctx4codec = NULL;
    
    // keep stream
    self.ref_stream = stream;
    self.index_stream = index;
    
    ret = (self.ref_stream != NULL && self.index_stream >= 0);
    CBRA(ret);
    
ERROR:
    if (!ret && errCode)
    {
        *errCode = err;
    }
    
    if (!ret && ctx4codec)
    {
        avcodec_free_context(&ctx4codec);
        ctx4codec = NULL;
    }
    
    if (!ret)
    {
        [self cleanup];
    }
    
    return ret;
}

- (BOOL)canHandlePacket:(AVPacket *)pkt
{
    return (self.index_stream >= 0 && pkt->stream_index == self.index_stream);
}

- (BOOL)appendPacket:(AVPacket *)pkt
{
    VHOSTTHREAD();
    
    return [self.pkt_queue appendPacket:pkt];
}

- (BOOL)popPacket:(AVPacket*)destPkt
{
    if (!AVSE_STATUS_IS_PLAYING() &&
        !AVSE_STATUS_IS_PREPARE() &&
        !AVSE_STATUS_IS_QUITING())
    {
        return NO;
    }
    
    return [self.pkt_queue popPacket:destPkt];
}

- (AVPacket*)topPacket
{
    if (!AVSE_STATUS_IS_PLAYING() &&
        !AVSE_STATUS_IS_PREPARE() &&
        !AVSE_STATUS_IS_QUITING())
    {
        return NULL;
    }
    
    return [self.pkt_queue topPacket];
}

- (AVCodecContext *)ctx_codec
{
    return m_ctx_codec;
}

- (BOOL)isFull
{
    VHOSTTHREAD();
    
    if ([self.pkt_queue length] > [self maxPacketQueued])
    {
        return YES;
    }
    
    return NO;
}

- (double)timestamp
{
    VNOIMPL();
    return 0.f;
}

- (double)delay4pts:(double)pts delayInPlan:(double)delay
{
    if (!self.ref_synccore)
    {
        VERROR();
        return delay;
    }
    
    // FIXME: drop the frame if diff a lot
    double diff = pts - [self.ref_synccore timestamp];
    if (diff < 0.f)
    {
        delay = 0.f;    // is slow
    }
    else if (diff > delay)
    {
        delay *= 2.0f;  // is ahead of the clock
    }
    
    return delay;
}

- (double)time_base
{
    // stream->time_base is good, NOT enc->time_base!
    return av_q2d([self ref_stream]->time_base);
}

#pragma mark Sub-category
- (int)maxPacketQueued
{
    return 64;
}

@end
