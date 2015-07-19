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

- (void)cleanup
{
    [self reset];
    
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
    [self.pkt_queue reset];
    
    return YES;
}

- (BOOL)attachTo:(AVStream*)stream err:(int*)errCode atIndex:(int)index
{
    BOOL ret = YES;
    int err = ERR_SUCCESS;
    AVCodecContext *enc = NULL;
    AVCodec *codec = NULL;
    AVCodecContext *ctx4codec = NULL;
    
    [self cleanup];
    
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
    return [self.pkt_queue appendPacket:pkt];
}

- (BOOL)popPacket:(AVPacket*)destPkt
{
    return [self.pkt_queue popPacket:destPkt];
}

- (AVPacket*)topPacket
{
    return [self.pkt_queue topPacket];
}

- (AVCodecContext *)ctx_codec
{
    return m_ctx_codec;
}

@end
