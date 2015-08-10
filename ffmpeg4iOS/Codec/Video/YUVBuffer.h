//
//  YUVBuffer.h
//  ffmpeg4iOS
//
//  Created by Wayne W on 15/8/2.
//  Copyright (c) 2015年 github.com/henern. All rights reserved.
//

#ifndef ffmpeg4iOS_YUVBuffer_h
#define ffmpeg4iOS_YUVBuffer_h

#import "libavformat/avformat.h"

@protocol DEF_CLASS(YUVBuffer) <NSObject>

- (const uint8_t*)componentY;
- (const uint8_t*)componentU;
- (const uint8_t*)componentV;
- (const uint8_t*)componentUV;      // if NV12

- (int64_t)pts;
- (enum AVPixelFormat)pix_fmt;
- (int)repeat_pict;

- (int32_t)width;
- (int32_t)height;

@end

#endif
