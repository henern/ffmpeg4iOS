//
//  OpenGLESTexProvider.h
//  ffmpeg4iOS
//
//  Created by Wayne W on 15/8/10.
//  Copyright (c) 2015年 github.com/henern. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "libavformat/avformat.h"
#import <CoreVideo/CoreVideo.h>

@protocol DEF_CLASS(OpenGLESTexProvider) <NSObject>

- (BOOL)supportPixelFmt:(OSType)fmt_type;

- (GLuint)ogl_texY4cache:(CVOpenGLESTextureCacheRef)texCache;

// NOTE: for those Y, U, and V are interspersed (e.g. 2VUY), this is the full YUV.
//       for those planar format (e.g. NV12), this is UV.
- (GLuint)ogl_texUV4cache:(CVOpenGLESTextureCacheRef)texCache;

@end
