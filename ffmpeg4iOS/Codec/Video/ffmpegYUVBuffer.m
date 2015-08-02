//
//  ffmpegYUVBuffer.m
//  ffmpeg4iOS
//
//  Created by Wayne W on 15/8/2.
//  Copyright (c) 2015年 github.com/henern. All rights reserved.
//

#import "ffmpegYUVBuffer.h"
#import "ehm.h"

@interface DEF_CLASS(ffmpegYUV420PBuffer) ()
{
    enum AVPixelFormat m_fmtPix;
    int m_width;
    int m_height;
    int64_t m_pts;
    int m_repeat_pict;
    
    NSMutableData *m_bufferYUV;
}
@end

@implementation DEF_CLASS(ffmpegYUV420PBuffer)

- (instancetype)initWithCodec:(AVCodecContext *)ctxCodec
{
    self = [super init];
    if (self && ctxCodec)
    {
        m_width = ctxCodec->width;
        m_height = ctxCodec->height;
    }
    else
    {
        VERROR();
    }
    
    return self;
}

- (BOOL)attach2frame:(AVFrame *)avfDecoded fmt:(enum AVPixelFormat)fmt
{
    BOOL ret = YES;
    
    [self cleanup];
    
    int err = ERR_SUCCESS;
    
    AVFrame *avpicYUV = av_frame_alloc();
    CPRA(avpicYUV);
    CPRA(avfDecoded);
    CBRA(fmt == AV_PIX_FMT_YUV420P);
    CBRA(m_width > 0 && m_height > 0);
    
    // buffer is re-usable
    if (!m_bufferYUV)
    {
        // allocate the YUV buffer
        m_bufferYUV = [NSMutableData dataWithLength:[self __size_per_picture_YUV420P]];
    }
    CPRA(m_bufferYUV);
    
    // keep the properties
    m_fmtPix = fmt;
    m_repeat_pict = avfDecoded->repeat_pict;
    
    // pts from ffmpeg
    m_pts = av_frame_get_best_effort_timestamp(avfDecoded);
    if (m_pts == AV_NOPTS_VALUE)
    {
        m_pts = 0.f;
    }
    CBRA(m_pts >= 0);
    
    // binding
    err = avpicture_fill((AVPicture*)avpicYUV, [m_bufferYUV mutableBytes], [self pix_fmt], [self width], [self height]);
    CBRA(err >= 0);
    
    // copy from planes to plain buffer
    av_picture_copy((AVPicture*)avpicYUV, (AVPicture *)avfDecoded, [self pix_fmt], [self width], [self height]);
    
ERROR:
    if (avpicYUV)
    {
        av_frame_free(&avpicYUV);
        avpicYUV = NULL;
    }
    
    if (ret)
    {
        err = ERR_SUCCESS;
    }
    else if (err == ERR_SUCCESS)
    {
        // return some error
        err = AVERROR_BUG;
    }
    
    return err;
}

- (void)dealloc
{
    [self cleanup];
}

- (void)cleanup
{
    m_repeat_pict = 0;
    m_pts = AV_NOPTS_VALUE;
    m_fmtPix = AV_PIX_FMT_NONE;
}

#pragma mark YUVBuffer
- (const uint8_t*)componentY
{
    return [m_bufferYUV bytes];
}

- (const uint8_t*)componentU
{
    return [self componentY] + [self width] * [self height];
}

- (const uint8_t*)componentV
{
    return ([self componentU] + [self width] * [self height] / 4);
}

- (int64_t)pts
{
    return m_pts;
}

- (enum AVPixelFormat)pix_fmt
{
    return m_fmtPix;
}

- (int)repeat_pict
{
    return m_repeat_pict;
}

- (int32_t)width
{
    return m_width;
}

- (int32_t)height
{
    return m_height;
}

#pragma mark private
- (int)__size_per_picture_YUV420P
{
    return avpicture_get_size(PIX_FMT_YUV420P, [self width], [self height]);
}

@end
