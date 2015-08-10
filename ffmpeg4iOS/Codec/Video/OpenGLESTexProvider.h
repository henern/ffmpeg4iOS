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

- (GLuint)ogl_texY4cache:(CVOpenGLESTextureCacheRef)texCache;
- (GLuint)ogl_texUV4cache:(CVOpenGLESTextureCacheRef)texCache;

@end
