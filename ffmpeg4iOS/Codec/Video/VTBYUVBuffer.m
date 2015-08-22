//
//  VTBYUVBuffer.m
//  ffmpeg4iOS
//
//  Created by Wayne W on 15/8/3.
//  Copyright (c) 2015年 github.com/henern. All rights reserved.
//

#import "VTBYUVBuffer.h"
#import "ehm.h"
#import "OGLCommon.h"
#import "VTBTexProvider.h"

@interface DEF_CLASS(VTBYUVBuffer) ()
{
    REF_CLASS(VTBTexProvider) m_texProvider;
    
    CVImageBufferRef m_imgBuffer;
    OSType m_fmt_type;
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
    OSType fmt_type = 0;
    uint8_t *base_address = NULL;
    
    [self cleanup];
    
    CPRA(imageBuffer);
    
    CVPixelBufferLockBaseAddress(imageBuffer, 0);
    
    fmt_type = CVPixelBufferGetPixelFormatType(imageBuffer);
    CBRA([DEF_CLASS(VTBTexProvider) supportPixFormat:fmt_type]);
    
    w = CVPixelBufferGetWidth(imageBuffer);
    h = CVPixelBufferGetHeight(imageBuffer);
    CBRA(w > 0 && h > 0);
    
    base_address = (uint8_t*)CVPixelBufferGetBaseAddress(imageBuffer);
    CPRA(base_address);
    
    // provider
    m_texProvider = [DEF_CLASS(VTBTexProvider) texProvider4type:fmt_type width:w height:h];
    CPRA(m_texProvider);
    ret = [m_texProvider refer2address:base_address];
    CBRA(ret);
    
    // detach
    m_imgBuffer = CVBufferRetain(imageBuffer);
    imageBuffer = NULL;
    
    m_fmt_type = fmt_type;
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
    return [m_texProvider width];
}

- (int32_t)height
{
    return [m_texProvider height];
}

- (const uint8_t*)componentY
{
    return [m_texProvider componentY];
}
- (const uint8_t*)componentU
{
    return [m_texProvider componentU];
}
- (const uint8_t*)componentV
{
    return [m_texProvider componentV];
}

- (const uint8_t*)componentUV
{
    return [m_texProvider componentUV];
}

- (int64_t)pts
{
    return m_pts;
}

- (enum AVPixelFormat)pix_fmt
{
    return [m_texProvider pix_fmt];
}

- (int)repeat_pict
{
    // FIXME: if repeat?
    return 0;
}

- (void)cleanup
{
    m_texProvider = nil;
    
    if (m_imgBuffer)
    {
#if 0
        FFMLOG_OC(@"cleanup with image-buffer %x", (void*)m_imgBuffer);
#endif

        CVPixelBufferUnlockBaseAddress(m_imgBuffer, 0);
        CVBufferRelease(m_imgBuffer);
        m_imgBuffer = NULL;
    }
    
    m_fmt_type = 0;
    m_pts = AV_NOPTS_VALUE;
}

#pragma mark OpenGLESTexProvider
- (GLuint)ogl_texY4cache:(CVOpenGLESTextureCacheRef)texCache
{
    return [m_texProvider ogl_texY4cache:texCache imgBuf:m_imgBuffer];
}

- (GLuint)ogl_texUV4cache:(CVOpenGLESTextureCacheRef)texCache
{
    return [m_texProvider ogl_texUV4cache:texCache imgBuf:m_imgBuffer];
}

- (BOOL)supportPixelFmt:(OSType)fmt_type
{
    return fmt_type == [m_texProvider pix_fmt];
}

@end
