//
//  VTB2VUYTexProvider.m
//  ffmpeg4iOS
//
//  Created by Wayne W on 15/8/19.
//  Copyright (c) 2015年 github.com/henern. All rights reserved.
//

#import "VTB2VUYTexProvider.h"

@implementation DEF_CLASS(VTB2VUYTexProvider)
{
    CVOpenGLESTextureRef m_oglTexY;
    CVOpenGLESTextureRef m_oglTex2VUY;
}

- (enum AVPixelFormat)pix_fmt
{
    return AV_PIX_FMT_UYVY422;
}

- (void)cleanup
{
    if (m_oglTex2VUY)
    {
        CFRelease(m_oglTex2VUY);
        m_oglTex2VUY = NULL;
    }

    if (m_oglTexY)
    {
        CFRelease(m_oglTexY);
        m_oglTexY = NULL;
    }
    
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
                                                 GL_RG_EXT,
                                                 m_width,
                                                 m_height,
                                                 GL_RG_EXT,
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
    
    if (m_oglTex2VUY)
    {
        tex = CVOpenGLESTextureGetName(m_oglTex2VUY);
        FINISH();
    }
    
    CPRA(texCache);
    CBRA(m_oglTex2VUY == NULL);
    
    CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
                                                 texCache,
                                                 imgBuffer,
                                                 NULL,
                                                 GL_TEXTURE_2D,
                                                 GL_RGBA,
                                                 m_width / 2,
                                                 m_height,
                                                 GL_RGBA,
                                                 GL_UNSIGNED_BYTE,
                                                 0,
                                                 &m_oglTex2VUY);
    CPRA(m_oglTex2VUY);
    
    tex = CVOpenGLESTextureGetName(m_oglTex2VUY);
    glBindTexture(CVOpenGLESTextureGetTarget(m_oglTex2VUY), tex);
    CBRA(OGLRET);
    
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    CBRA(OGLRET);
    
DONE:
ERROR:
    if (!ret && m_oglTex2VUY)
    {
        VERROR();
        CFRelease(m_oglTex2VUY);
        m_oglTex2VUY = NULL;
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
