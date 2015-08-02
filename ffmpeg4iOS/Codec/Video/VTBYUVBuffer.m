//
//  VTBYUVBuffer.m
//  ffmpeg4iOS
//
//  Created by Wayne W on 15/8/3.
//  Copyright (c) 2015年 github.com/henern. All rights reserved.
//

#import "VTBYUVBuffer.h"
#import "ehm.h"
#import "Common.h"

@interface DEF_CLASS(VTBYUVBuffer) ()
{
    CVImageBufferRef m_imgBuffer;
    
    int32_t m_width;
    int32_t m_height;
    CVPlanarPixelBufferInfo_YCbCrPlanar *m_planars;
    OSType m_fmt_type;
    
    int32_t m_offst_Y;
    int32_t m_offst_U;
    int32_t m_offst_V;
    
    int64_t m_pts;
}
@end

@implementation DEF_CLASS(VTBYUVBuffer)

- (void)dealloc
{
    [self cleanup];
}

- (BOOL)isReady
{
    return (m_imgBuffer != nil);
}

- (BOOL)attach2imageBuf:(CVImageBufferRef)imageBuffer pts:(int64_t)pts
{
    BOOL ret = YES;
    
    size_t w = 0;
    size_t h = 0;
    CVPlanarPixelBufferInfo_YCbCrPlanar *planars = NULL;
    OSType fmt_type = 0;
    
    [self cleanup];
    
    CPRA(imageBuffer);
    
    CVPixelBufferLockBaseAddress(imageBuffer, 0);
    
    fmt_type = CVPixelBufferGetPixelFormatType(imageBuffer);
    CBRA(fmt_type == kCVPixelFormatType_420YpCbCr8Planar);
    
    w = CVPixelBufferGetWidth(imageBuffer);
    h = CVPixelBufferGetHeight(imageBuffer);
    CBRA(w > 0 && h > 0);
    
    planars = (CVPlanarPixelBufferInfo_YCbCrPlanar*)CVPixelBufferGetBaseAddress(imageBuffer);
    CPRA(planars);
    
    // detach
    m_imgBuffer = CVBufferRetain(imageBuffer);
    imageBuffer = NULL;
    
    m_width = (int32_t)w;
    m_height = (int32_t)h;
    m_planars = planars;
    m_fmt_type = fmt_type;
    
    m_offst_Y = BINT32ToUInt32((uint8_t*)&m_planars->componentInfoY.offset);
    m_offst_U = BINT32ToUInt32((uint8_t*)&m_planars->componentInfoCb.offset);
    m_offst_V = BINT32ToUInt32((uint8_t*)&m_planars->componentInfoCr.offset);
    
    m_pts = pts;
    
ERROR:
    if (imageBuffer)
    {
        CVPixelBufferUnlockBaseAddress(imageBuffer, 0);
        imageBuffer = NULL;
    }
    
    return ret;
}

- (int32_t)width
{
    return m_width;
}

- (int32_t)height
{
    return m_height;
}

- (const uint8_t*)componentY
{
    return m_offst_Y + (const uint8_t*)m_planars;
}
- (const uint8_t*)componentU
{
    return m_offst_U + (const uint8_t*)m_planars;
}
- (const uint8_t*)componentV
{
    return m_offst_V + (const uint8_t*)m_planars;
}

- (int64_t)pts
{
    return m_pts;
}

- (enum AVPixelFormat)pix_fmt
{
    VBR(![self isReady] ||
        m_fmt_type == kCVPixelFormatType_420YpCbCr8Planar);
    
    return AV_PIX_FMT_YUV420P;
}

- (int)repeat_pict
{
    // FIXME: if repeat?
    return 0;
}

- (void)cleanup
{
    if (m_imgBuffer)
    {
        FFMLOG_OC(@"cleanup with image-buffer %x", (void*)m_imgBuffer);

        CVPixelBufferUnlockBaseAddress(m_imgBuffer, 0);
        CVBufferRelease(m_imgBuffer);
        m_imgBuffer = NULL;
    }
    
    m_width = 0;
    m_height = 0;
    m_planars = NULL;
    m_fmt_type = 0;
    
    m_offst_Y = 0;
    m_offst_U = 0;
    m_offst_V = 0;
    
    m_pts = AV_NOPTS_VALUE;
}

@end
