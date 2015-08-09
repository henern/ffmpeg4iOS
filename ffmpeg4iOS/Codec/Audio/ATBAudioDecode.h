//
//  ATBAudioDecode.h
//  ffmpeg4iOS
//
//  Created by Wayne W on 15/8/9.
//  Copyright (c) 2015年 github.com/henern. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import "libavformat/avformat.h"

#define UNKNOWN_CODEC_ID        (-1)

@protocol DEF_CLASS(ATBAudioDecode) <NSObject>

// flush cache to AQBuffer,
// ready == NO means no more flush, try to decode next
- (BOOL)flush2outputBuf:(AudioQueueBufferRef)buffer
              timestamp:(AudioTimeStamp*)audioTS
                  codec:(AVCodecContext*)ctx_codec
                  ready:(BOOL*)ready;

// decode packet and flush
// ready == NO means no buffer is ready for playback, try to get next packet
- (BOOL)decodeAudioPacket:(AVPacket*)pkt
                outputBuf:(AudioQueueBufferRef)buffer
                timestamp:(AudioTimeStamp*)audioTS
                time_base:(double)time_base
                    codec:(AVCodecContext*)ctx_codec
                    ready:(BOOL*)ready;

// info for buffer pool
- (BOOL)outputBufferSize:(uint32_t*)inBufferByteSize
          numberPktDescr:(uint32_t*)inNumberPacketDescriptions
                   codec:(AVCodecContext*)ctx_codec
               forStream:(AVStream*)avStream;

// update AudioStreamBasicDescription
- (BOOL)description:(AudioStreamBasicDescription*)description
              codec:(AVCodecContext*)ctx_codec
          forStream:(AVStream*)avStream;

// reset
- (void)reset;

@end
