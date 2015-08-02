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

void ffmpeg_audioQueueOutputCallback(void *info, AudioQueueRef unused, AudioQueueBufferRef buffer);

@interface DEF_CLASS(AudioToolBoxEngine) ()
{
    AudioQueueRef m_audioQueue;
    AudioQueueBufferRef m_audioBuffers[AUDIO_BUFFER_QUANTITY];
    BOOL m_flagBufferInQueue[AUDIO_BUFFER_QUANTITY];
}

@property (atomic, assign) BOOL stoppingQueue;
@property (atomic, assign) int64_t pts_sample_start;

@end

@implementation DEF_CLASS(AudioToolBoxEngine)

- (void)dealloc
{
    [self cleanup];
}

- (BOOL)attachTo:(AVStream *)stream err:(int *)errCode atIndex:(int)index
{
    BOOL ret = [super attachTo:stream err:errCode atIndex:index];
    CBRA(ret);
    
    ret = [self __setup2stream:stream err:errCode];
    CBRA(ret);
    
ERROR:
    return ret;
}

- (BOOL)appendPacket:(AVPacket *)pkt
{
    BOOL ret = [super appendPacket:pkt];
    CBRA(ret);
    
    ret = [self __try2refillBuffers];
    CBRA(ret);
    
ERROR:
    return ret;
}

- (double)timestamp
{
    AudioTimeStamp tmstmp = {0};
    AudioQueueGetCurrentTime(m_audioQueue, NULL, &tmstmp, NULL);
    
    // sample_start is non-0 if seek
    int64_t sample_start = 0;
    if (self.pts_sample_start != AV_NOPTS_VALUE)
    {
        sample_start = self.pts_sample_start;
    }
    
    if ((tmstmp.mFlags & kAudioTimeStampSampleTimeValid) != 0)
    {
        // mSampleTime == how many samples have been played.
        tmstmp.mSampleTime += sample_start;
        return tmstmp.mSampleTime / [self ctx_codec]->sample_rate;
    }
    
    return 0.f;
}

#pragma mark private
#define UNKNOWN_CODEC_ID        (-1)
- (BOOL)__setup2stream:(AVStream*)stream err:(int *)errCode
{
    VHOSTTHREAD();
    
    BOOL ret = YES;
    
    int err = ERR_SUCCESS;
    AudioStreamBasicDescription audioFormat = {0};
    
    AVCodecContext *codec = [self ctx_codec];
    CPRA(codec);
    
    // clean
    ret = [self reset];
    VBR(ret);
    
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
            // FIXME: oops hw decoder is NOT available.
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
        uint32_t bufferByteSize = (int)(codec->bit_rate * AUDIO_BUFFER_SECONDS / 8);
        uint32_t numberPacket = (int)(codec->sample_rate * AUDIO_BUFFER_SECONDS / codec->frame_size + 1);
        
        FFMLOG(@"%u packet capacity, %d byte capacity", numberPacket, bufferByteSize);
        
        err = AudioQueueAllocateBufferWithPacketDescriptions(m_audioQueue,
                                                             bufferByteSize,
                                                             numberPacket,
                                                             m_audioBuffers + i);
        CBRA(err == ERR_SUCCESS);
    }

ERROR:
    if (!ret)
    {
        stream->discard = AVDISCARD_ALL;
        [self cleanup];
    }

    if (!ret && errCode)
    {
        *errCode = err;
    }
    
    return ret;
}

- (BOOL)__fillBuffer:(AudioQueueBufferRef)buffer
{
    BOOL ret = YES;
    OSStatus err = ERR_SUCCESS;
    AudioTimeStamp bufStartTime = {0};
    
    // init
    buffer->mAudioDataByteSize = 0;
    buffer->mPacketDescriptionCount = 0;
    
    while (buffer->mPacketDescriptionCount < buffer->mPacketDescriptionCapacity)
    {
        // AudioQueueStop is ongoing, any pending packets should be discarded.
        if (self.stoppingQueue)
        {
            FINISH();
        }
        
        AVPacket *top = [self topPacket];
        if (!top && buffer->mPacketDescriptionCount == 0)
        {
            // FIXME: queue is empty, block?
            sleep(1);
            continue;
        }
                
        if (top &&
            buffer->mAudioDataBytesCapacity - buffer->mAudioDataByteSize >= top->size)
        {
            int indx_pkt_in_buf = 0;
            
            AVPacket pkt = {0};
            ret = [self popPacket:&pkt];
            CBR(ret);
            
            // append one packet-description
            indx_pkt_in_buf = buffer->mPacketDescriptionCount;
            buffer->mPacketDescriptionCount++;
            
            if (indx_pkt_in_buf == 0)
            {
                bufStartTime.mSampleTime = pkt.pts;
                bufStartTime.mFlags = kAudioTimeStampSampleTimeValid;
            }
            
            memcpy((uint8_t *)buffer->mAudioData + buffer->mAudioDataByteSize, pkt.data, pkt.size);
            buffer->mPacketDescriptions[indx_pkt_in_buf].mStartOffset = buffer->mAudioDataByteSize;
            buffer->mPacketDescriptions[indx_pkt_in_buf].mDataByteSize = pkt.size;
            buffer->mPacketDescriptions[indx_pkt_in_buf].mVariableFramesInPacket = [self ctx_codec]->frame_size;
            
            // sum
            buffer->mAudioDataByteSize += pkt.size;
            
            // free
            av_free_packet(&pkt);
            
            // try to fill more
            continue;
        }
        
        break;
    }
    
    // NOTE: keep the first pts of playback, it's not 0 if seek.
    //       check -[self timestamp] for more details.
    if (self.pts_sample_start == AV_NOPTS_VALUE)
    {
        self.pts_sample_start = bufStartTime.mSampleTime;
    }
    
    VBR(self.pts_sample_start != AV_NOPTS_VALUE);
    if (self.pts_sample_start != AV_NOPTS_VALUE)
    {
        // if seek, this step can fix the time,
        // so that AudioQ will play the buffer immediately.
        bufStartTime.mSampleTime -= self.pts_sample_start;
    }
    
    CBRA(buffer->mPacketDescriptionCount > 0);
    
    err = AudioQueueEnqueueBufferWithParameters(m_audioQueue,
                                                buffer,
                                                0,
                                                NULL,
                                                0, 0, 0,
                                                NULL,
                                                &bufStartTime,
                                                NULL);
    CBR(err == ERR_SUCCESS);
    
ERROR:
DONE:
    FFMLOG_OC(@"%@(%ld) to enqueue a buffer with #%d packets, at %lf",
              ret? @"SUCCEED" : @"FAILED",
              err,
              buffer->mPacketDescriptionCount,
              bufStartTime.mSampleTime);
    
    return ret;
}

- (BOOL)__try2refillBuffers
{
    VHOSTTHREAD();
    
    BOOL ret = YES;
    int err = ERR_SUCCESS;
    
    if (!AVSE_STATUS_IS_PREPARE())
    {
        return YES;
    }
    
    for (int i = 0; i < AUDIO_BUFFER_QUANTITY; i++)
    {
        if (m_flagBufferInQueue[i])
        {
            continue;
        }

        if (m_audioBuffers[i] == NULL)
        {
            VBR(0);
            return NO;
        }
        
        m_flagBufferInQueue[i] = YES;
        return [self __fillBuffer:m_audioBuffers[i]];
    }
    
    err = AudioQueuePrime(m_audioQueue, 0, NULL);
    CBRA(err == ERR_SUCCESS);
    AVSE_STATUS_UNSET(AVSTREAM_ENGINE_STATUS_PREPARE);
    
ERROR:
    return YES;
}

#pragma mark clean
- (void)cleanup
{
    if (!m_audioQueue)
    {
        VBR(m_audioBuffers[0] == NULL);
        
        return;
    }
    
    for (int i = 0; i < AUDIO_BUFFER_QUANTITY; i++)
    {
        // AudioQueueDispose will free the buffer
        m_audioBuffers[i] = NULL;
    }

    AudioQueueDispose(m_audioQueue, YES);
    m_audioQueue = NULL;
    
    [super cleanup];
}

- (BOOL)reset
{
    // status ==> PREPARE
    [super reset];
    
    if (m_audioQueue)
    {
        // AudioQueueStop will invoke callbacks for all pending buffers synchronously.
        // so we need a flag here to discard all pending packets.
        self.stoppingQueue = YES;
        AudioQueueStop(m_audioQueue, YES);
        self.stoppingQueue = NO;
    }
    
    for (int i = 0; i < AUDIO_BUFFER_QUANTITY; i++)
    {
        m_flagBufferInQueue[i] = NO;
    }
    self.pts_sample_start = AV_NOPTS_VALUE;
    
    return YES;
}

- (BOOL)doPlay
{
    BOOL ret = YES;
    int err = ERR_SUCCESS;
    
    CBR(!AVSE_STATUS_IS_PREPARE());
    CBRA(!AVSE_STATUS_IS_PLAYING());
    
    err = AudioQueueStart(m_audioQueue, NULL);
    CBRA(err == ERR_SUCCESS);
    
ERROR:
    return ret;
}

- (BOOL)doPause
{
    BOOL ret = YES;
    int err = ERR_SUCCESS;
    
    CBRA(AVSE_STATUS_IS_PLAYING());
    
    err = AudioQueuePause(m_audioQueue);
    CBRA(err == ERR_SUCCESS);
    
ERROR:
    return ret;
}

@end

void ffmpeg_audioQueueOutputCallback(void *info, AudioQueueRef unused, AudioQueueBufferRef buffer)
{
    @autoreleasepool
    {
    
    REF_CLASS(AudioToolBoxEngine) engine = (__bridge REF_CLASS(AudioToolBoxEngine))info;
    VBR([engine isKindOfClass:[DEF_CLASS(AudioToolBoxEngine) class]]);
    
    BOOL ret = [engine __fillBuffer:buffer];
    UNUSE(ret);
        
    }
}
