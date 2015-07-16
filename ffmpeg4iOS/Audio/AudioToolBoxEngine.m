//
//  AudioToolBoxEngine.m
//  ffmpeg4iOS
//
//  Created by Wayne W. on 15/7/16.
//  Copyright (c) 2015年 github.com/henern. All rights reserved.
//

#import "AudioToolBoxEngine.h"
#import "ehm.h"
#import <AudioToolbox/AudioToolbox.h>

#define AUDIO_BUFFER_QUANTITY       3
#define AUDIO_BUFFER_SECONDS        1

void ffmpeg_audioQueueOutputCallback(void *info, AudioQueueRef unused, AudioQueueBufferRef buffer)
{
}

@interface DEF_CLASS(AudioToolBoxEngine) ()
{
    AudioQueueRef m_audioQueue;
    AudioQueueBufferRef m_audioBuffers[AUDIO_BUFFER_QUANTITY];
    
    NSMutableArray *m_audioPacketQueue;
    NSLock *m_audioPacketQueueLock;
}

@end

@implementation DEF_CLASS(AudioToolBoxEngine)

- (void)dealloc
{
    [self __cleanup];
}

- (BOOL)attachTo:(AVStream *)stream err:(int *)errCode
{
    BOOL ret = [super attachTo:stream err:errCode];
    CBRA(ret);
    
    ret = [self __setup2stream:stream err:errCode];
    CBRA(ret);
    
ERROR:
    return ret;
}

#define UNKNOWN_CODEC_ID        (-1)
- (BOOL)__setup2stream:(AVStream*)stream err:(int *)errCode
{
    BOOL ret = YES;
    
    int err = ERR_SUCCESS;
    AudioStreamBasicDescription audioFormat = {0};
    
    AVCodecContext *codec = stream->codec;
    CPRA(codec);
    
    audioFormat.mFormatID = UNKNOWN_CODEC_ID;
    audioFormat.mSampleRate = codec->sample_rate;
    audioFormat.mFormatFlags = 0;
    
    // find the codec
    switch (codec->codec_id)
    {
        case CODEC_ID_MP3:
            audioFormat.mFormatID = kAudioFormatMPEGLayer3;
            break;
        case CODEC_ID_AAC:
            audioFormat.mFormatID = kAudioFormatMPEG4AAC;
            audioFormat.mFormatFlags = kMPEG4Object_AAC_Main;
            break;
        case CODEC_ID_AC3:
            audioFormat.mFormatID = kAudioFormatAC3;
            break;
        default:
            FFMLOG(@"Error: audio format %d is not supported", codec->codec_id);
            audioFormat.mFormatID = kAudioFormatAC3;
            break;
    }
    CBRA(audioFormat.mFormatID != UNKNOWN_CODEC_ID);
    
    audioFormat.mBytesPerPacket = 0;
    audioFormat.mFramesPerPacket = codec->frame_size;
    audioFormat.mBytesPerFrame = 0;
    audioFormat.mChannelsPerFrame = codec->channels;
    audioFormat.mBitsPerChannel = 0;
    
    // launch the queue and callback
    err = AudioQueueNewOutput(&audioFormat,
                              ffmpeg_audioQueueOutputCallback,
                              (__bridge void*)self,
                              NULL,
                              NULL,
                              0,
                              &m_audioQueue);
    CBRA(err == ERR_SUCCESS);
    CPRA(m_audioQueue);
    
    // allocate audio buffers
    for (int i = 0; i < AUDIO_BUFFER_QUANTITY; i++)
    {
        UInt32 bufferByteSize = (int)(codec->bit_rate * AUDIO_BUFFER_SECONDS / 8);
        UInt32 numberPacket = (int)(codec->sample_rate * AUDIO_BUFFER_SECONDS / codec->frame_size + 1);
        
        FFMLOG(@"%d packet capacity, %d byte capacity", numberPacket, bufferByteSize);
        
        err = AudioQueueAllocateBufferWithPacketDescriptions(m_audioQueue,
                                                             bufferByteSize,
                                                             numberPacket,
                                                             m_audioBuffers + i);
        CBRA(err != ERR_SUCCESS);
    }
    
    m_audioPacketQueue = [[NSMutableArray alloc] init];
    m_audioPacketQueueLock = [[NSLock alloc] init];

ERROR:
    if (!ret)
    {
        stream->discard = AVDISCARD_ALL;
        [self __cleanup];
    }

    if (!ret && errCode)
    {
        *errCode = err;
    }
    
    ret = YES;  // it's NOT ciritcal if error in audio
    return ret;
}

- (void)__cleanup
{
    if (!m_audioQueue)
    {
        VBR(m_audioBuffers[0] == NULL);
        VBR(m_audioPacketQueue == nil);
        VBR(m_audioPacketQueueLock == nil);
        
        return;
    }
    
    for (int i = 0; i < AUDIO_BUFFER_QUANTITY; i++)
    {
        // AudioQueueDispose will free the buffer
        m_audioBuffers[i] = NULL;
    }

    AudioQueueDispose(m_audioQueue, YES);
    m_audioQueue = NULL;
    
    m_audioPacketQueue = nil;
    
    [m_audioPacketQueueLock unlock];
    m_audioPacketQueueLock = nil;
}
@end

