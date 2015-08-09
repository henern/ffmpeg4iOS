//
//  AudioToolBoxEngine.m
//  ffmpeg4iOS
//
//  Created by Wayne W. on 15/7/16.
//  Copyright (c) 2015年 github.com/henern. All rights reserved.
//

#import "AudioToolBoxEngine.h"
#import "ehm.h"
#import "ATBAudioDecodeFactory.h"
#import <AudioToolbox/AudioToolbox.h>

#define AUDIO_BUFFER_QUANTITY       3

void ffmpeg_audioQueueOutputCallback(void *info, AudioQueueRef unused, AudioQueueBufferRef buffer);

@interface DEF_CLASS(AudioToolBoxEngine) ()
{
    AudioQueueRef m_audioQueue;
    AudioQueueBufferRef m_audioBuffers[AUDIO_BUFFER_QUANTITY];
    BOOL m_flagBufferInQueue[AUDIO_BUFFER_QUANTITY];
    
    id<DEF_CLASS(ATBAudioDecode)> m_decoder;
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
    
    VBR(m_decoder == nil);
    m_decoder = [DEF_CLASS(ATBAudioDecodeFactory) audioDecoder4codec:codec];
    CPRA(m_decoder);
    
    ret = [m_decoder description:&audioFormat codec:codec forStream:stream];
    CBRA(ret);
    
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
        uint32_t bufferByteSize = 0;
        uint32_t numberPacket = 0;
        
        ret = [m_decoder outputBufferSize:&bufferByteSize
                           numberPktDescr:&numberPacket
                                    codec:codec
                                forStream:stream];
        CBRA(ret);
        
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
        BOOL ready = NO;
        
        // AudioQueueStop is ongoing, any pending packets should be discarded.
        if (self.stoppingQueue)
        {
            FINISH();
        }
        
        // flush pending buffer if there
        ret = [m_decoder flush2outputBuf:buffer
                               timestamp:&bufStartTime
                                   codec:[self ctx_codec]
                                   ready:&ready];
        CBRA(ret);
        
        if (ready)
        {
            break;
        }
        
        AVPacket *top = [self topPacket];
        if (!top && buffer->mPacketDescriptionCount == 0)
        {
            // FIXME: queue is empty, block?
            sleep(1);
            continue;
        }
                
        if (top)
        {
            AVPacket pkt = {0};
            ret = [self popPacket:&pkt];
            CBR(ret);
            
            ret = [m_decoder decodeAudioPacket:&pkt
                                     outputBuf:buffer
                                     timestamp:&bufStartTime
                                     time_base:[self time_base]
                                         codec:[self ctx_codec]
                                         ready:&ready];
            CBRA(ret);
            
            // free
            av_free_packet(&pkt);
            
            if (ready)
            {
                break;
            }
            
            // try to fill more
            continue;
        }
        
        break;
    }
    
    CBR(buffer->mPacketDescriptionCount > 0);
    
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
        
        // for some codec, __fillBuffer may fail for 1st packat, it's ignorable.
        if ([self __fillBuffer:m_audioBuffers[i]])
        {
            m_flagBufferInQueue[i] = YES;
        }
        
        return YES;
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
    
    // reset decoder
    [m_decoder reset];
    
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
