//
//  VTBTexProvider.m
//  ffmpeg4iOS
//
//  Created by Wayne W on 15/8/19.
//  Copyright (c) 2015年 github.com/henern. All rights reserved.
//

#import "VTBTexProvider.h"
#import "VTBNV12TexProvider.h"
#import "VTB2VUYTexProvider.h"

@implementation DEF_CLASS(VTBTexProvider)

+ (REF_CLASS(VTBTexProvider))texProvider4type:(OSType)fmt_type
                                        width:(size_t)width
                                       height:(size_t)height
{
    BOOL ret = YES;
    REF_CLASS(VTBTexProvider) provider = nil;
    
    CBRA(width > 0 && height > 0);
    
    if (fmt_type == kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange)
    {
        provider = [[DEF_CLASS(VTBNV12TexProvider) alloc] init];
    }
    else if (fmt_type == kCVPixelFormatType_422YpCbCr8)
    {
        provider = [[DEF_CLASS(VTB2VUYTexProvider) alloc] init];
    }
    else
    {
        VERROR();
        provider = [[DEF_CLASS(VTBTexProvider) alloc] init];
    }
    CPRA(provider);
    
    provider->m_width = (int32_t)width;
    provider->m_height = (int32_t)height;
    
ERROR:
    return provider;
}

+ (BOOL)supportPixFormat:(OSType)fmt_type
{
    return (fmt_type == kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange ||
            fmt_type == kCVPixelFormatType_422YpCbCr8);
}

#pragma mark public
- (BOOL)refer2address:(const uint8_t*)base_address
{
    if (base_address)
    {
        m_base_address = base_address;
        return YES;
    }

    VERROR();
    return NO;
}

- (const uint8_t*)base_address
{
    return m_base_address;
}

- (void)cleanup
{
    m_width = 0;
    m_height = 0;
    m_base_address = NULL;
}

- (void)dealloc
{
    [self cleanup];
}

#pragma mark YUVBuffer
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
    VERROR();
    return NULL;
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
    VERROR();
    return NULL;
}

- (int64_t)pts
{
    VERROR();
    return 0;
}

- (enum AVPixelFormat)pix_fmt
{
    VERROR();
    return AV_PIX_FMT_NONE;
}

- (int)repeat_pict
{
    VERROR();
    return 0;
}

#pragma mark OpenGLESTexProvider-like
- (GLuint)ogl_texY4cache:(CVOpenGLESTextureCacheRef)texCache imgBuf:(CVImageBufferRef)imgBuf
{
    VERROR();
    return 0;
}

- (GLuint)ogl_texUV4cache:(CVOpenGLESTextureCacheRef)texCache imgBuf:(CVImageBufferRef)imgBuf
{
    VERROR();
    return 0;
}

@end
