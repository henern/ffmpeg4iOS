//
//  VTBVideoDecode.m
//  ffmpeg4iOS
//
//  Created by Wayne W on 15/8/2.
//  Copyright (c) 2015年 github.com/henern. All rights reserved.
//

#import "VTBVideoDecode.h"
#import "AVC/AVCRaw.h"
#import "Utility.h"
#import "ehm.h"
#import "VTBYUVBuffer.h"

typedef struct
{
    int64_t pts;
}VTB_DECODE_FRAME_CONTEXT;

@interface DEF_CLASS(VTBVideoDecode) ()
{
    VTDecompressionSessionRef m_video_decode_session;
    CMFormatDescriptionRef m_h264_fmt_desc;
    
    NSMutableArray *m_pendingYUV;
}

- (BOOL)__pushYUV:(REF_CLASS(VTBYUVBuffer))yuv;
- (REF_CLASS(VTBYUVBuffer))__popYUV;

@end

// callback for VTB
void vtb_video_decode_callback(void *decompressionOutputRefCon,
                               void *sourceFrameRefCon,
                               OSStatus status,
                               VTDecodeInfoFlags infoFlags,
                               CVImageBufferRef imageBuffer,
                               CMTime presentationTimeStamp,
                               CMTime presentationDuration )
{
    BOOL ret = YES;
    
    VTB_DECODE_FRAME_CONTEXT *ctx_frame = (VTB_DECODE_FRAME_CONTEXT*)sourceFrameRefCon;
    REF_CLASS(VTBVideoDecode) vtb = (__bridge REF_CLASS(VTBVideoDecode))decompressionOutputRefCon;
    REF_CLASS(VTBYUVBuffer) yuvBuf = nil;
    
    CPRA(ctx_frame);
    CPRA(imageBuffer);
    CBRA([vtb isKindOfClass:[DEF_CLASS(VTBVideoDecode) class]]);
    
    yuvBuf = [[DEF_CLASS(VTBYUVBuffer) alloc] init];
    CPRA(yuvBuf);
    
    ret = [yuvBuf attach2imageBuf:imageBuffer pts:ctx_frame->pts];
    CBRA(ret);
    
    // lock is not required here,
    // callback and VTDecompressionSessionDecodeFrame run in the same thread
    ret = [vtb __pushYUV:yuvBuf];
    CBRA(ret);
    
ERROR:
    if (ctx_frame)
    {
        free(ctx_frame);
        ctx_frame = NULL;
    }
    
    return;
}

@implementation DEF_CLASS(VTBVideoDecode)

+ (BOOL)supportCodec:(AVCodecContext *)ctxCodec
{
    if (IOS8_OR_LATER() && ctxCodec->codec_id == AV_CODEC_ID_H264)
    {
        return YES;
    }
    
    return NO;
}

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        m_pendingYUV = [NSMutableArray arrayWithCapacity:16];
    }
    
    return self;
}

- (void)dealloc
{
    [self cleanup];
}

- (int)decodePacket:(AVPacket *)pkt
          yuvBuffer:(__autoreleasing id<DEF_CLASS(YUVBuffer)> *)yuvBuffer
              codec:(AVCodecContext *)ctxCodec
           finished:(int *)finished
{
    BOOL ret = YES;
    int err = ERR_SUCCESS;
    
    VTDecodeInfoFlags flag_decode_info = 0;
    CMSampleBufferRef sample_buf = NULL;
    REF_CLASS(VTBYUVBuffer) yuv = nil;
    VTB_DECODE_FRAME_CONTEXT *ctxFrame = NULL;
    
    // callback config
    VTDecompressionOutputCallbackRecord callbackRec = {vtb_video_decode_callback, (__bridge void*)self};
    
    // we need NV12, not YUV420P
    // YUV420P is NOT OpenGLES compatible, which cost glTexImage2D ~100ms
    NSDictionary *destImgBufAttr = [NSDictionary dictionaryWithObjectsAndKeys:
                                    [NSNumber numberWithBool:YES], (id)kCVPixelBufferOpenGLESCompatibilityKey, nil];
    
    CPRA(pkt);
    CPRA(ctxCodec);
    CPRA(finished);
    CPRA(yuvBuffer);
    
    // reset
    *finished = 0;
    
    // h264 format
    if (!m_h264_fmt_desc)
    {
        // format description
        ret = [self __avcConfig4codec:ctxCodec avc_fmt:&m_h264_fmt_desc];
        CBRA(ret);
    }
    CPRA(m_h264_fmt_desc);
    
    // sample
    err = [self __sampleBuf4packet:pkt codec_fmt:m_h264_fmt_desc sampleBuf:&sample_buf];
    CBRA(err == ERR_SUCCESS);
    
    if (!m_video_decode_session)
    {
        err = VTDecompressionSessionCreate(kCFAllocatorDefault,
                                           m_h264_fmt_desc,
                                           nil,
                                           (__bridge CFDictionaryRef)destImgBufAttr,
                                           &callbackRec,
                                           &m_video_decode_session);
        CBRA(err == ERR_SUCCESS);
    }
    CPRA(m_video_decode_session);
    
    ctxFrame = malloc(sizeof(VTB_DECODE_FRAME_CONTEXT));
    CPRA(ctxFrame);
    ctxFrame->pts = pkt->pts;
    
    err = VTDecompressionSessionDecodeFrame(m_video_decode_session,
                                            sample_buf,
                                            0,
                                            (void*)ctxFrame,
                                            &flag_decode_info);
    CBRA(err == ERR_SUCCESS);
    
    // callback should free this
    ctxFrame = NULL;
    
    yuv = [self __popYUV];
    if ([yuv isReady])
    {
        *finished = 1;
        
        // detach
        *yuvBuffer = yuv;
        yuv = nil;
    }
    
ERROR:
    if (ctxFrame)
    {
        free(ctxFrame);
        ctxFrame = NULL;
    }
    
    if (sample_buf)
    {
        CFRelease(sample_buf);
        sample_buf = NULL;
    }
    
    if (ret)
    {
        err = ERR_SUCCESS;
    }
    else if (err == ERR_SUCCESS)
    {
        err = AVERROR_BUG;
    }
    
    return err;
}

#pragma mark private
- (BOOL)__avcConfig4codec:(AVCodecContext*)ctxCodec
                  avc_fmt:(CMFormatDescriptionRef*)avc_fmt
{
    BOOL ret = YES;
    
    uint8_t *cursor = NULL;
    AVC_DecoderConfigurationRecord *avc_decConfigRec = NULL;
    CMFormatDescriptionRef fmt = NULL;
    
    NSData *buf_SPS = nil;
    NSData *buf_PPS = nil;
    
    CPRA(ctxCodec);
    CPRA(ctxCodec->extradata);
    CBRA(ctxCodec->extradata_size > sizeof(AVC_DecoderConfigurationRecord));
    CPRA(avc_fmt);
    
    avc_decConfigRec = (AVC_DecoderConfigurationRecord*)ctxCodec->extradata;
    CPRA(avc_decConfigRec);
    
    cursor = &avc_decConfigRec->lengthSizeMinusOne;
    cursor++;
    
    // SPS
    {
        AVC_SequenceParameterSets *avc_SPS = (AVC_SequenceParameterSets*)cursor;
        VPR(avc_SPS);

        int avc_sps_len = BINT16ToUInt16(&avc_SPS->size[0]);
        CBRA(avc_sps_len > 0);
        
        // check NALU type
        CBRA((avc_SPS->NALUnits[0] & 0x1F) == 7);
        
        // only support one sps
        CBRA((avc_SPS->number & 0x1F) == 1);
        
        // fill
        cursor = &avc_SPS->NALUnits[0];
        buf_SPS = [NSData dataWithBytes:cursor length:avc_sps_len];
        VBR([buf_SPS length] == avc_sps_len);
        
        // next set
        cursor += avc_sps_len;
    }
    
    // PPS
    {
        AVC_PictureParameterSets *avc_PPS = (AVC_PictureParameterSets*)cursor;
        VPR(avc_PPS);
        
        int avc_pps_len = BINT16ToUInt16(&avc_PPS->size[0]);
        CBRA(avc_pps_len > 0);
        
        // only support one PPS
        CBRA((avc_PPS->number & 0x1F) == 1);
        
        // check NALU type
        CBRA((avc_PPS->NALUnits[0] & 0x1F) == 8);
        
        // fill
        cursor = &avc_PPS->NALUnits[0];
        buf_PPS = [NSData dataWithBytes:cursor length:avc_pps_len];
        VBR([buf_PPS length] == avc_pps_len);
        
        // next set
        cursor += avc_pps_len;
    }
    
    CBRA((cursor - ctxCodec->extradata) <= ctxCodec->extradata_size);
    
    {
        const uint8_t* const paramSetPtrs[2] = { (const uint8_t*)[buf_SPS bytes],
                                                 (const uint8_t*)[buf_PPS bytes] };
        const size_t paramSetSizes[2] = { [buf_SPS length],
                                          [buf_PPS length] };
        
        int err = CMVideoFormatDescriptionCreateFromH264ParameterSets(kCFAllocatorDefault,
                                                                      2,
                                                                      paramSetPtrs,
                                                                      paramSetSizes,
                                                                      4,
                                                                      &fmt);
        CBRA(err == ERR_SUCCESS);
        CPRA(fmt);
    }
    
    // detach
    *avc_fmt = fmt;
    fmt = NULL;
    
ERROR:
    if (fmt)
    {
        CFRelease(fmt);
        fmt = NULL;
    }
    
    return ret;
}

- (int)__sampleBuf4packet:(AVPacket*)pkt
                codec_fmt:(CMFormatDescriptionRef)codec_fmt
                sampleBuf:(CMSampleBufferRef*)sampleBuf
{
    BOOL ret = YES;
    int err = ERR_SUCCESS;
    
    CMBlockBufferRef dataBlock = nil;
    CMSampleBufferRef sample = nil;
    
    CPRA(sampleBuf);
    
    // block buffer
    err = CMBlockBufferCreateWithMemoryBlock(NULL,
                                             pkt->data,
                                             pkt->size,
                                             kCFAllocatorNull,
                                             NULL,
                                             0,
                                             pkt->size,
                                             0,
                                             &dataBlock);
    CBRA(err == kCMBlockBufferNoErr);
    CPRA(dataBlock);
    
    err = CMSampleBufferCreate(NULL,
                               dataBlock,
                               TRUE,
                               NULL,
                               NULL,
                               codec_fmt,
                               1,
                               0,
                               NULL,
                               0,
                               NULL,
                               &sample);
    CBRA(err == ERR_SUCCESS);
    CPRA(sample);
    
    // detach
    *sampleBuf = sample;
    sample = NULL;
    
ERROR:
    if (dataBlock)
    {
        CFRelease(dataBlock);
        dataBlock = NULL;
    }
    
    if (sample)
    {
        CFRelease(sample);
        sample = NULL;
    }
    
    if (ret)
    {
        err = ERR_SUCCESS;
    }
    else if (err == ERR_SUCCESS)
    {
        err = AVERROR_BUG;
    }
    
    return err;
}

- (BOOL)__pushYUV:(REF_CLASS(VTBYUVBuffer))yuv
{
    if (yuv)
    {
        VBR([m_pendingYUV count] == 0);     // suppose one buffer
        [m_pendingYUV addObject:yuv];
        return YES;
    }
    
    return NO;
}

- (REF_CLASS(VTBYUVBuffer))__popYUV
{
    REF_CLASS(VTBYUVBuffer) yuv = (REF_CLASS(VTBYUVBuffer))[m_pendingYUV firstObject];
    
    if (yuv)
    {
        [m_pendingYUV removeObjectAtIndex:0];
        return yuv;
    }

    return nil;
}

- (void)cleanup
{
    if (m_h264_fmt_desc)
    {
        CFRelease(m_h264_fmt_desc);
        m_h264_fmt_desc = NULL;
    }
    
    if (m_video_decode_session)
    {
        VTDecompressionSessionInvalidate(m_video_decode_session);
        CFRelease(m_video_decode_session);
        m_video_decode_session = NULL;
    }
    
    [m_pendingYUV removeAllObjects];
}

@end
