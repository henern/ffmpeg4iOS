//
//  AudioEngine.m
//  ffmpeg4iOS
//
//  Created by Wayne W. on 15/7/16.
//  Copyright (c) 2015年 github.com/henern. All rights reserved.
//

#import "AudioEngine.h"

@implementation DEF_CLASS(AudioEngine)

- (BOOL)appendPacket:(AVPacket *)pkt
{
    [super appendPacket:pkt];
    
#if 0
    if (!audioDTSQuotient && packet.dts > 0)
    {
        audioDTSQuotient = packet.dts;
    }
    
    if (audioDTSQuotient > 0)
    {
        packet.dts /= audioDTSQuotient;
    }
    
    if (packet.dts < 0) {
        packet.dts = 0;
    }
    
    if (prevAudioDts > packet.dts) {
        audioDtsOffset += prevAudioDts - packet.dts;
    }
    prevAudioDts = packet.dts;
    
    packet.dts += audioDtsOffset;
    
    [audioPacketQueueLock lock];
    audioPacketQueueSize += packet.size;
    [audioPacketQueue addObject:[NSMutableData dataWithBytes:&packet length:sizeof(packet)]];
    [audioPacketQueueLock unlock];
    
    if (emptyAudioBuffer) {
        [self fillAudioBuffer:emptyAudioBuffer];
    }
#endif
}

@end
