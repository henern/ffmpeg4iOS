//
//  VTBNV12TexProvider.m
//  ffmpeg4iOS
//
//  Created by Wayne W on 15/8/19.
//  Copyright (c) 2015年 github.com/henern. All rights reserved.
//

#import "VTBNV12TexProvider.h"
#import "Common.h"

@implementation DEF_CLASS(VTBNV12TexProvider)
{
    int32_t m_offst_Y;
    int32_t m_offst_UV;
    
    CVOpenGLESTextureRef m_oglTexY;
    CVOpenGLESTextureRef m_oglTexUV;
}

- (BOOL)refer2address:(const uint8_t *)base_address
{
    CVPlanarPixelBufferInfo_YCbCrBiPlanar *planars = NULL;
    
    BOOL ret = [super refer2address:base_address];
    CBRA(ret);
    
    planars = (CVPlanarPixelBufferInfo_YCbCrBiPlanar*)[self base_address];
    CPRA(planars);
    
    m_offst_Y = BINT32ToUInt32((uint8_t*)&planars->componentInfoY.offset);
    m_offst_UV = BINT32ToUInt32((uint8_t*)&planars->componentInfoCbCr.offset);
    
ERROR:
    return ret;
}

- (const uint8_t*)componentY
{
    return m_offst_Y + [self base_address];
}

- (const uint8_t*)componentUV
{
    return m_offst_UV + [self base_address];
}

- (enum AVPixelFormat)pix_fmt
{
    return AV_PIX_FMT_NV12;
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
    
    m_offst_Y = 0;
    m_offst_UV = 0;
    
    [super cleanup];
}

- (GLuint)ogl_texY4cache:(CVOpenGLESTextureCacheRef)texCache imgBuf:(CVImageBufferRef)imgBuffer
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
                                                 imgBuffer,
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

- (GLuint)ogl_texUV4cache:(CVOpenGLESTextureCacheRef)texCache imgBuf:(CVImageBufferRef)imgBuffer
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
                                                 imgBuffer,
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
