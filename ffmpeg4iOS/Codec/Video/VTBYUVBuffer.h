//
//  VTBYUVBuffer.h
//  ffmpeg4iOS
//
//  Created by Wayne W on 15/8/3.
//  Copyright (c) 2015年 github.com/henern. All rights reserved.
//

#import "YUVBuffer.h"
#import <VideoToolbox/VideoToolbox.h>
#import "OpenGLESTexProvider.h"

@interface DEF_CLASS(VTBYUVBuffer) : NSObject <DEF_CLASS(YUVBuffer), DEF_CLASS(OpenGLESTexProvider)>

- (BOOL)attach2imageBuf:(CVImageBufferRef)imgBuf pts:(int64_t)pts;
- (BOOL)isReady;

@end
