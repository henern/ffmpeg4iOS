//
//  VTBTexProvider.h
//  ffmpeg4iOS
//
//  Created by Wayne W on 15/8/19.
//  Copyright (c) 2015年 github.com/henern. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OpenGLESTexProvider.h"
#import "OGLCommon.h"
#import "YUVBuffer.h"

@interface DEF_CLASS(VTBTexProvider) : NSObject <DEF_CLASS(YUVBuffer)>
{
    int32_t m_width;
    int32_t m_height;
    
    const uint8_t *m_base_address;
}

+ (REF_CLASS(VTBTexProvider))texProvider4type:(OSType)fmt_type
                                        width:(size_t)width
                                       height:(size_t)height;
+ (BOOL)supportPixFormat:(OSType)fmt_type;

- (BOOL)refer2address:(const uint8_t*)base_address;
- (const uint8_t*)base_address;
- (void)cleanup;

@end

@interface DEF_CLASS(VTBTexProvider) (OpenGLESTexProvider)

- (GLuint)ogl_texY4cache:(CVOpenGLESTextureCacheRef)texCache imgBuf:(CVImageBufferRef)imgBuf;
- (GLuint)ogl_texUV4cache:(CVOpenGLESTextureCacheRef)texCache imgBuf:(CVImageBufferRef)imgBuf;

@end
