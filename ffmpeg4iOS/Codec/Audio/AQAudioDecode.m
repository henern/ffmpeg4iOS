//
//  AQAudioDecode.m
//  ffmpeg4iOS
//
//  Created by Wayne W on 15/8/9.
//  Copyright (c) 2015年 github.com/henern. All rights reserved.
//

#import "AQAudioDecode.h"
#import "ehm.h"

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
                    codec:(AVCodecContext*)ctx_codec
                    ready:(BOOL*)ready
{
    BOOL ret = YES;
    int indx_pkt_in_buf = 0;
    
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
    buffer->mPacketDescriptions[indx_pkt_in_buf].mVariableFramesInPacket = ctx_codec->frame_size;
    
    // sum
    buffer->mAudioDataByteSize += pkt.size;
 
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
    
ERROR:
    return ret;
}
#undef audioFormat

- (void)reset
{
    
}

@end
