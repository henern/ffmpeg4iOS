//
//  ffmpegAudioDecode.m
//  ffmpeg4iOS
//
//  Created by Wayne W on 15/8/9.
//  Copyright (c) 2015年 github.com/henern. All rights reserved.
//

#import "ffmpegAudioDecode.h"
#import "ehm.h"
#import "libswresample/swresample.h"

#define TARGET_SAMPLE_AUDIO_FMT             AV_SAMPLE_FMT_FLT

@interface DEF_CLASS(ffmpegAudioDecode) ()
{
    SwrContext *m_pSwrCtx;
    
    NSMutableData *m_swrBuf;
    int32_t m_offset_swrBuf;
    int32_t m_len_swrBuf;
    int64_t m_best_pts_base;
}
@end

@implementation DEF_CLASS(ffmpegAudioDecode)

- (BOOL)flush2outputBuf:(AudioQueueBufferRef)buffer
              timestamp:(AudioTimeStamp*)bufStartTime
                  codec:(AVCodecContext*)ctx_codec
                  ready:(BOOL*)ready
{
    BOOL ret = YES;
    int32_t nb_samples = 0;
    int indx_pkt_in_buf = 0;
    
    *ready = NO;
    
    if (m_len_swrBuf == 0)
    {
        FINISH();
    }
    
    uint8_t *cursor = (uint8_t *)[m_swrBuf bytes] + m_offset_swrBuf;
    CBRA(m_offset_swrBuf >= 0);
    
    int32_t dest_len = MIN(buffer->mAudioDataBytesCapacity - buffer->mAudioDataByteSize, m_len_swrBuf);
    CBRA(dest_len > 0);
    
    nb_samples = dest_len / (av_get_bytes_per_sample(TARGET_SAMPLE_AUDIO_FMT) * ctx_codec->channels);
    CBRA(nb_samples > 0);
    dest_len = nb_samples * (av_get_bytes_per_sample(TARGET_SAMPLE_AUDIO_FMT) * ctx_codec->channels);
    
    // append one packet-description
    indx_pkt_in_buf = buffer->mPacketDescriptionCount;
    buffer->mPacketDescriptionCount++;
    
    if (indx_pkt_in_buf == 0)
    {
        VBR(m_best_pts_base != AV_NOPTS_VALUE);
        bufStartTime->mSampleTime = m_best_pts_base;
        bufStartTime->mFlags = kAudioTimeStampSampleTimeValid;
        
        m_best_pts_base += nb_samples;
    }
    
    memcpy((uint8_t *)buffer->mAudioData + buffer->mAudioDataByteSize, cursor, dest_len);
    buffer->mPacketDescriptions[indx_pkt_in_buf].mStartOffset = buffer->mAudioDataByteSize;
    buffer->mPacketDescriptions[indx_pkt_in_buf].mDataByteSize = dest_len;
    buffer->mPacketDescriptions[indx_pkt_in_buf].mVariableFramesInPacket = 1;
    
    // sum
    buffer->mAudioDataByteSize += dest_len;
    
    // move cursor
    m_offset_swrBuf += dest_len;
    m_len_swrBuf -= dest_len;
    CBRA(m_len_swrBuf >= 0);
    
    *ready = YES;
    
DONE:
ERROR:
    return ret;
}

- (BOOL)decodeAudioPacket:(AVPacket*)pkt
                outputBuf:(AudioQueueBufferRef)buffer
                timestamp:(AudioTimeStamp*)bufStartTime
                time_base:(double)time_base
                    codec:(AVCodecContext*)codec
                    ready:(BOOL*)ready
{
    BOOL ret = YES;
    int32_t pkt_size = 0;
    AVFrame *avfDecoded = av_frame_alloc();
    int got_frame = 0;
    int decode_len = 0;
    int64_t expect_pts = AV_NOPTS_VALUE;
    BOOL big_fix_to_pts = NO;
    
    CPRA(buffer);
    CPRA(bufStartTime);
    CPRA(ready);
    CPRA(codec);
    CPRA(pkt);
    
    *ready = NO;
    
    pkt_size = pkt->size;
    CBRA(pkt_size > 0);
    
DECODE_PKT:
    
    // ffmpeg decode
    decode_len = avcodec_decode_audio4(codec, avfDecoded, &got_frame, pkt);
    CBRA(decode_len > 0);
    pkt_size -= decode_len;
    
    // no frame, quit
    if (0 == got_frame)
    {
        *ready = YES;
        FINISH();
    }
    
    {
        uint8_t *ptr_out = NULL;
        int swr_ret = 0;
        int in_samples = avfDecoded->nb_samples;
        
        // required buffer-size
        int avf_size = av_samples_get_buffer_size(avfDecoded->linesize,
                                                  codec->channels,
                                                  avfDecoded->nb_samples,
                                                  TARGET_SAMPLE_AUDIO_FMT,
                                                  0);
        
        // re-allocate if not enough
        if (!m_swrBuf || [m_swrBuf length] < avf_size)
        {
            m_swrBuf = [NSMutableData dataWithLength:avf_size];
        }
        CBRA([m_swrBuf length] >= avf_size);
        ptr_out = [m_swrBuf mutableBytes];
        
        // convert
        swr_ret = swr_convert(m_pSwrCtx,
                              (uint8_t **)(&ptr_out),
                              in_samples,
                              (const uint8_t **)avfDecoded->extended_data,
                              in_samples);
        CBRA(swr_ret > 0);

        // update buffer info
        m_offset_swrBuf = 0;
        m_len_swrBuf = avf_size;
        
        // pts from ffmpeg
        expect_pts = av_frame_get_best_effort_timestamp(avfDecoded) * time_base * av_frame_get_sample_rate(avfDecoded);
        CBRA(expect_pts != AV_NOPTS_VALUE);
        
        // for some audio trak, pts may change a lot suddenly, because ffmpeg is fixing it.
        big_fix_to_pts = (llabs(expect_pts - m_best_pts_base) * 2 > av_frame_get_sample_rate(avfDecoded));
        
        // NOTE: ONLY refresh m_best_pts_base if NOPTS, or there is a fix.
        //       but in normal case, expect_pts is inaccurate, which cause much noise in audio playback.
        //       we should update m_best_pts_base by counting the frames.
        if (m_best_pts_base == AV_NOPTS_VALUE || big_fix_to_pts)
        {
            m_best_pts_base = expect_pts;
        }
        
        // flush
        ret = [self flush2outputBuf:buffer
                          timestamp:bufStartTime
                              codec:codec
                              ready:ready];
        CBRA(ret);
    }
    
    // free frame
    av_frame_free(&avfDecoded);
    avfDecoded = NULL;
    
    // packet has some move data, re-decode
    if (pkt_size > 0)
    {
        VERROR();
#if 0
        goto DECODE_PKT;
#else
        // FIXME: need to support multiple avcodec_decode_audio4 on one packet
        CBRA(0);
#endif
    }
    
DONE:
ERROR:
    if (avfDecoded)
    {
        av_frame_free(&avfDecoded);
    }
    
    return ret;
}

- (BOOL)outputBufferSize:(uint32_t*)bufferByteSize
          numberPktDescr:(uint32_t*)numberPacket
                   codec:(AVCodecContext*)ctx_codec
               forStream:(AVStream*)avStream
{
    *numberPacket = 512;
    *bufferByteSize = av_samples_get_buffer_size(NULL,
                                                 ctx_codec->channels,
                                                 *numberPacket,
                                                 TARGET_SAMPLE_AUDIO_FMT,
                                                 0);
    
    return *bufferByteSize > 0 && *numberPacket > 0;
}

- (BOOL)description:(AudioStreamBasicDescription*)audioFormat
              codec:(AVCodecContext*)codec
          forStream:(AVStream*)avStream
{
    BOOL ret = YES;
    int err = ERR_SUCCESS;
    
    audioFormat->mSampleRate = codec->sample_rate;
    audioFormat->mFormatID = kAudioFormatLinearPCM;
    audioFormat->mFormatFlags = kAudioFormatFlagsNativeFloatPacked;
    audioFormat->mFramesPerPacket = 1;
    audioFormat->mChannelsPerFrame = codec->channels;
    
    audioFormat->mBitsPerChannel = 8 * av_get_bytes_per_sample(TARGET_SAMPLE_AUDIO_FMT);
    audioFormat->mBytesPerFrame = audioFormat->mChannelsPerFrame * audioFormat->mBitsPerChannel / 8;
    audioFormat->mBytesPerPacket = audioFormat->mFramesPerPacket * audioFormat->mBytesPerFrame;
    
    CBRA(audioFormat->mFormatID != UNKNOWN_CODEC_ID);
    
    // cleanup
    if (m_pSwrCtx)
    {
        VERROR();       // cleanup should be excuted first
        
        swr_free(&m_pSwrCtx);
        m_pSwrCtx = NULL;
    }
    
    // sample_fmt ==> TARGET_SAMPLE_AUDIO_FMT
    m_pSwrCtx = swr_alloc_set_opts(m_pSwrCtx,
                                   av_get_default_channel_layout(codec->channels),
                                   TARGET_SAMPLE_AUDIO_FMT,
                                   codec->sample_rate,
                                   codec->channel_layout,
                                   codec->sample_fmt,
                                   codec->sample_rate,
                                   0,
                                   0);
    CPRA(m_pSwrCtx);
    
    err = swr_init(m_pSwrCtx);
    CBRA(err >= ERR_SUCCESS);
    
ERROR:
    return ret;
}

- (void)reset
{
    m_swrBuf = nil;
    m_offset_swrBuf = 0;
    m_len_swrBuf = 0;
    m_best_pts_base = AV_NOPTS_VALUE;
}

- (void)cleanup
{
    swr_free(&m_pSwrCtx);
    VBR(NULL == m_pSwrCtx);
}

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        [self reset];
    }
    
    return self;
}

- (void)dealloc
{
    [self cleanup];
}


@end
