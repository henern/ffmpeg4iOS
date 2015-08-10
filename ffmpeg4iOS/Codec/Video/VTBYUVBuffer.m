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
#import "OGLCommon.h"

@interface DEF_CLASS(VTBYUVBuffer) ()
{
    CVImageBufferRef m_imgBuffer;
    CVOpenGLESTextureRef m_oglTexY;
    CVOpenGLESTextureRef m_oglTexUV;
    
    int32_t m_width;
    int32_t m_height;
    CVPlanarPixelBufferInfo_YCbCrBiPlanar *m_planars;
    OSType m_fmt_type;
    
    int32_t m_offst_Y;
    int32_t m_offst_UV;
    
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
    CVPlanarPixelBufferInfo_YCbCrBiPlanar *planars = NULL;
    OSType fmt_type = 0;
    
    [self cleanup];
    
    CPRA(imageBuffer);
    
    CVPixelBufferLockBaseAddress(imageBuffer, 0);
    
    fmt_type = CVPixelBufferGetPixelFormatType(imageBuffer);
    CBRA(fmt_type == kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange);
    
    w = CVPixelBufferGetWidth(imageBuffer);
    h = CVPixelBufferGetHeight(imageBuffer);
    CBRA(w > 0 && h > 0);
    
    planars = (CVPlanarPixelBufferInfo_YCbCrBiPlanar*)CVPixelBufferGetBaseAddress(imageBuffer);
    CPRA(planars);
    
    // detach
    m_imgBuffer = CVBufferRetain(imageBuffer);
    imageBuffer = NULL;
    
    m_width = (int32_t)w;
    m_height = (int32_t)h;
    m_planars = planars;
    m_fmt_type = fmt_type;
    
    m_offst_Y = BINT32ToUInt32((uint8_t*)&m_planars->componentInfoY.offset);
    m_offst_UV = BINT32ToUInt32((uint8_t*)&m_planars->componentInfoCbCr.offset);
    
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
    VERROR();
    return NULL;
}
- (const uint8_t*)componentV
{
    VERROR();
    return NULL;
}

- (const uint8_t*)componentUV
{
    return m_offst_UV + (const uint8_t*)m_planars;
}

- (int64_t)pts
{
    return m_pts;
}

- (enum AVPixelFormat)pix_fmt
{
    VBR(![self isReady] ||
        m_fmt_type == kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange);
    
    return AV_PIX_FMT_NV12;
}

- (int)repeat_pict
{
    // FIXME: if repeat?
    return 0;
}

- (void)cleanup
{
    if (m_oglTexY)
    {
        CFRelease(m_oglTexY);
        m_oglTexY = NULL;
    }
    
    if (m_oglTexUV)
    {
        CFRelease(m_oglTexUV);
        m_oglTexUV = NULL;
    }
    
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
    m_offst_UV = 0;
    
    m_pts = AV_NOPTS_VALUE;
}

#pragma mark OpenGLESTexProvider
- (GLuint)ogl_texY4cache:(CVOpenGLESTextureCacheRef)texCache
{
    BOOL ret = YES;
    GLuint tex = NULL;
    
    if (m_oglTexY)
    {
        tex = CVOpenGLESTextureGetName(m_oglTexY);
        FINISH();
    }
    
    CPRA(texCache);
    CBRA(m_oglTexY == NULL);
    
    CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
                                                 texCache,
                                                 m_imgBuffer,
                                                 NULL,
                                                 GL_TEXTURE_2D,
                                                 GL_RED_EXT,
                                                 m_width,
                                                 m_height,
                                                 GL_RED_EXT,
                                                 GL_UNSIGNED_BYTE,
                                                 0,
                                                 &m_oglTexY);
    CPRA(m_oglTexY);
    
    tex = CVOpenGLESTextureGetName(m_oglTexY);
    glBindTexture(CVOpenGLESTextureGetTarget(m_oglTexY), tex);
    CBRA(OGLRET);
    
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    CBRA(OGLRET);
    
DONE:
ERROR:
    if (!ret && m_oglTexY)
    {
        VERROR();
        CFRelease(m_oglTexY);
        m_oglTexY = NULL;
    }
    
    if (!ret && tex)
    {
        VERROR();
        glDeleteTextures(1, &tex);
        tex = NULL;
    }
    
    return tex;
}

- (GLuint)ogl_texUV4cache:(CVOpenGLESTextureCacheRef)texCache
{
    BOOL ret = YES;
    GLuint tex = NULL;
    
    if (m_oglTexUV)
    {
        tex = CVOpenGLESTextureGetName(m_oglTexUV);
        FINISH();
    }
    
    CPRA(texCache);
    CBRA(m_oglTexUV == NULL);
    
    // much faster than glTexImage2D (CPU 65% ==> 20%)
    CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
                                                 texCache,
                                                 m_imgBuffer,
                                                 NULL,
                                                 GL_TEXTURE_2D,
                                                 GL_RG_EXT,
                                                 m_width / 2,
                                                 m_height / 2,
                                                 GL_RG_EXT,
                                                 GL_UNSIGNED_BYTE,
                                                 1,
                                                 &m_oglTexUV);
    CPRA(m_oglTexUV);
    
    tex = CVOpenGLESTextureGetName(m_oglTexUV);
    glBindTexture(CVOpenGLESTextureGetTarget(m_oglTexUV), tex);
    CBRA(OGLRET);
    
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    CBRA(OGLRET);
    
DONE:
ERROR:
    if (!ret && m_oglTexUV)
    {
        VERROR();
        CFRelease(m_oglTexUV);
        m_oglTexUV = NULL;
    }
    
    if (!ret && tex)
    {
        VERROR();
        glDeleteTextures(1, &tex);
        tex = NULL;
    }
    
    return tex;
}

@end
