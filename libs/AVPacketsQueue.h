//
//  AVPacketsQueue.h
//  ffmpeg4iOS
//
//  Created by Wayne W. on 15/7/17.
//  Copyright (c) 2015年 github.com/henern. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "libavcodec/avcodec.h"

@interface DEF_CLASS(AVPacketsQueue) : NSObject

- (int64_t)totalSize;       // sum
- (UInt32)length;           // how many

- (BOOL)appendPacket:(AVPacket*)pkt;
- (BOOL)popPacket:(AVPacket*)destPkt;
- (AVPacket*)topPacket;

- (BOOL)reset;
- (BOOL)cleanup;

@end
