//
//  AQAudioDecode.m
//  ffmpeg4iOS
//
//  Created by Wayne W on 15/8/9.
//  Copyright (c) 2015年 github.com/henern. All rights reserved.
//

#import "AQAudioDecode.h"
#import "ehm.h"
#import "ADTSRaw.h"

@implementation DEF_CLASS(AQAudioDecode)

- (BOOL)flush2outputBuf:(AudioQueueBufferRef)buffer
              timestamp:(AudioTimeStamp *)audioTS
                  codec:(AVCodecContext*)ctx_codec
                  ready:(BOOL*)ready
{
    *ready = NO;
    return YES;
}

#define pkt             (*ref_pkt)
#define bufStartTime    (*audioTS)
- (BOOL)decodeAudioPacket:(AVPacket*)ref_pkt
                outputBuf:(AudioQueueBufferRef)buffer
                timestamp:(AudioTimeStamp *)audioTS
                time_base:(double)time_base
                    codec:(AVCodecContext*)ctx_codec
                    ready:(BOOL*)ready
{
    BOOL ret = YES;
    int indx_pkt_in_buf = 0;
    
    const uint8_t *audio_data = pkt.data;
    int audio_size = pkt.size;
    
    // skip adts if need
    int header4adts = CALL_FUNC(checkADTSHeader)(audio_data, audio_size);
    audio_data += header4adts;
    audio_size -= header4adts;
    
    // append one packet-description
    indx_pkt_in_buf = buffer->mPacketDescriptionCount;
    buffer->mPacketDescriptionCount++;
    
    if (indx_pkt_in_buf == 0)
    {
        bufStartTime.mSampleTime = pkt.pts;
        bufStartTime.mFlags = kAudioTimeStampSampleTimeValid;
    }
    
    memcpy((uint8_t *)buffer->mAudioData + buffer->mAudioDataByteSize, audio_data, audio_size);
    buffer->mPacketDescriptions[indx_pkt_in_buf].mStartOffset = buffer->mAudioDataByteSize;
    buffer->mPacketDescriptions[indx_pkt_in_buf].mDataByteSize = audio_size;
    buffer->mPacketDescriptions[indx_pkt_in_buf].mVariableFramesInPacket = ctx_codec->frame_size;
    
    // sum
    buffer->mAudioDataByteSize += audio_size;
 
    *ready = YES;
    
ERROR:
    return ret;
}
#undef pkt
#undef bufStartTime

#define AUDIO_BUFFER_SECONDS        1
- (BOOL)outputBufferSize:(uint32_t*)bufferByteSize
          numberPktDescr:(uint32_t*)numberPacket
                   codec:(AVCodecContext*)codec
               forStream:(AVStream*)avStream
{
    *bufferByteSize = (int)(codec->bit_rate * AUDIO_BUFFER_SECONDS / 8);
    *numberPacket = (int)(codec->sample_rate * AUDIO_BUFFER_SECONDS / codec->frame_size + 1);
    
    return YES;
}

#define audioFormat         (*description)
- (BOOL)description:(AudioStreamBasicDescription*)description
              codec:(AVCodecContext*)codec
          forStream:(AVStream*)avStream
{
    BOOL ret = YES;
    
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
        {
            if (codec->profile == FF_PROFILE_AAC_HE)
            {
                audioFormat.mFormatID = kAudioFormatMPEG4AAC_HE;
            }
            else if (codec->profile == FF_PROFILE_AAC_HE_V2)
            {
                audioFormat.mFormatID = kAudioFormatMPEG4AAC_HE_V2;
            }
            else
            {
                audioFormat.mFormatID = kAudioFormatMPEG4AAC;
                audioFormat.mFormatFlags = kMPEG4Object_AAC_Main;
            }
            
            if (codec->profile == FF_PROFILE_AAC_LOW)
            {
                audioFormat.mFormatFlags = kMPEG4Object_AAC_LC;
            }
            else if (codec->profile == FF_PROFILE_AAC_SSR)
            {
                audioFormat.mFormatFlags = kMPEG4Object_AAC_SSR;
            }
            else if (codec->profile == FF_PROFILE_AAC_LTP)
            {
                audioFormat.mFormatFlags = kMPEG4Object_AAC_LTP;
            }
            else if (codec->profile == FF_PROFILE_AAC_LD)
            {
                // no mapping flag in AudioQueue, use default
                VERROR();
            }
            
            break;
        }
        case CODEC_ID_ALAC:
        {
            audioFormat.mFormatID = kAudioFormatAppleLossless;      // NOT verified yet
            break;
        }
        default:
        {
            VERROR();
            // FIXME: oops hw decoder is NOT available.
            FFMLOG(@"Error: audio format %d is not supported", codec->codec_id);
            audioFormat.mFormatID = kAudioFormatLinearPCM;
            break;
        }
    }
    CBRA(audioFormat.mFormatID != UNKNOWN_CODEC_ID);
    
    audioFormat.mBytesPerPacket = 0;
    audioFormat.mFramesPerPacket = codec->frame_size;
    audioFormat.mBytesPerFrame = 0;
    audioFormat.mChannelsPerFrame = codec->channels;
    audioFormat.mBitsPerChannel = 0;
    
ERROR:
    return ret;
}
#undef audioFormat

- (void)reset
{
    
}

@end
