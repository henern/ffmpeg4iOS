//
//  ffmpegVideoDecode.m
//  ffmpeg4iOS
//
//  Created by Wayne W on 15/8/2.
//  Copyright (c) 2015年 github.com/henern. All rights reserved.
//

#import "ffmpegVideoDecode.h"
#import "ehm.h"
#import "ffmpegYUVBuffer.h"

@interface DEF_CLASS(ffmpegVideoDecode) ()
{
    REF_CLASS(ffmpegYUV420PBuffer) m_bufYUV;
}

@end

@implementation DEF_CLASS(ffmpegVideoDecode)

+ (BOOL)supportCodec:(AVCodecContext *)ctxCodec
{
    return YES;
}

- (int)decodePacket:(AVPacket *)pkt
          yuvBuffer:(__autoreleasing id<DEF_CLASS(YUVBuffer)> *)yuvBuffer
              codec:(AVCodecContext *)ctxCodec
           finished:(int *)finished
{
    BOOL ret = YES;
    int err = ERR_SUCCESS;
    
    AVFrame *avfDecoded = av_frame_alloc();
    
    CPRA(ctxCodec);
    CPRA(pkt);
    CPRA(yuvBuffer);
    CPRA(finished);
    
    err = avcodec_decode_video2(ctxCodec, avfDecoded, finished, pkt);
    CBR(err >= 0);
    
    // buffer is re-usable
    if (!m_bufYUV)
    {
        m_bufYUV = [[DEF_CLASS(ffmpegYUV420PBuffer) alloc] initWithCodec:ctxCodec];
    }
    CPRA(m_bufYUV);
    
    err = [m_bufYUV attach2frame:avfDecoded fmt:ctxCodec->pix_fmt];
    CBRA(err == ERR_SUCCESS);
    
    *yuvBuffer = m_bufYUV;
    
ERROR:
    if (avfDecoded)
    {
        av_frame_free(&avfDecoded);
        avfDecoded = NULL;
    }
    
    if (err < 0)
    {
        FFMLOG_OC(@"FAILED to decode a video-packet (error:%d, pts:%ld)", err, pkt->pts);
    }
    
    return err;
}

@end
