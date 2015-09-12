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
#import "libavformat/avc.h"

#define MAX_DELAYED_PIC         8

@interface DEF_CLASS(VTBVideoDecode) ()
{
    VTDecompressionSessionRef m_video_decode_session;
    CMFormatDescriptionRef m_h264_fmt_desc;
    
    NSMutableArray *m_pendingYUV;
    
    BOOL m_require_startcode2len;
    int m_count4delayedPic;
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
    @autoreleasepool
    {
    BOOL ret = YES;
    
    REF_CLASS(VTB_DECODE_FRAME_CONTEXT) ctx_frame = (__bridge_transfer REF_CLASS(VTB_DECODE_FRAME_CONTEXT))sourceFrameRefCon;
    REF_CLASS(VTBVideoDecode) vtb = ctx_frame.vtb;
    REF_CLASS(VTBYUVBuffer) yuvBuf = nil;
    
    CPRA(ctx_frame);
    CPR(imageBuffer);
    CBRA([vtb isKindOfClass:[DEF_CLASS(VTBVideoDecode) class]]);
    
    yuvBuf = [[DEF_CLASS(VTBYUVBuffer) alloc] init];
    CPRA(yuvBuf);
    
    ret = [yuvBuf attach2imageBuf:imageBuffer pts:ctx_frame.pts];
    CBRA(ret);
    
    // lock is not required here,
    // callback and VTDecompressionSessionDecodeFrame run in the same thread
    ret = [vtb __pushYUV:yuvBuf];
    CBRA(ret);
    
ERROR:
    
    return;
    }
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
    REF_CLASS(VTB_DECODE_FRAME_CONTEXT) ctxFrame = nil;
    
    // callback config
    VTDecompressionOutputCallbackRecord callbackRec = {vtb_video_decode_callback, (__bridge void*)self};
    
    // we need NV12 or 2VUY (OpenGLES-compatible), not YUV420P.
    // it costs VTB a lot to run the conversion (NV12 ==> YUV420P).
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
    
    ctxFrame = [[DEF_CLASS(VTB_DECODE_FRAME_CONTEXT) alloc] init];
    CPRA(ctxFrame);
    ctxFrame.pts = pkt->pts;
    ctxFrame.vtb = self;
    
    // synchronous, read RenderBase for more details.
    err = VTDecompressionSessionDecodeFrame(m_video_decode_session,
                                            sample_buf,
                                            0,
                                            (__bridge_retained void*)ctxFrame,
                                            &flag_decode_info);
    // callback should free this
    ctxFrame = nil;
    CBR(err == ERR_SUCCESS);
    
    yuv = [self __popYUV];
    if ([yuv isReady])
    {
        *finished = 1;
        
        // detach
        *yuvBuffer = yuv;
        yuv = nil;
    }
    
ERROR:
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

- (int)count4pendingYUVBuffers
{
    return (int)[m_pendingYUV count];
}

#pragma mark private
- (BOOL)__avcConfig4codec:(AVCodecContext*)ctxCodec
                  avc_fmt:(CMFormatDescriptionRef*)avc_fmt
{
    BOOL ret = YES;
    
    CMFormatDescriptionRef fmt = NULL;
    
    uint8_t *extradata = NULL;
    int extradata_size = 0;
    
    NSMutableData *buf_SPS = [NSMutableData dataWithCapacity:64];
    NSMutableData *buf_PPS = [NSMutableData dataWithCapacity:64];
    
    CPRA(ctxCodec);
    CPRA(ctxCodec->extradata);
    CPRA(avc_fmt);
    
    // FIXME: 2 is a magic number here, remove it if i find where the size of reorder-buffer is.
    m_count4delayedPic = ctxCodec->has_b_frames + 4;
    CBRA(0 <= m_count4delayedPic && m_count4delayedPic < MAX_DELAYED_PIC);
    
    // for more details, check https://developer.apple.com/videos/wwdc/2014/#513
    if ([self __extradataIsNALU:ctxCodec->extradata size:ctxCodec->extradata_size])
    {
        // mark
        m_require_startcode2len = YES;
        
        // nalu ==> avcC
        AVIOContext *pb = NULL;
        int err = avio_open_dyn_buf(&pb);
        CBRA(err == ERR_SUCCESS);
        ff_isom_write_avcc(pb, ctxCodec->extradata, ctxCodec->extradata_size);
        extradata_size = avio_close_dyn_buf(pb, &extradata);
    }
    else
    {
        extradata = ctxCodec->extradata;
        extradata_size = ctxCodec->extradata_size;
    }
    CPRA(extradata);
    CBRA(extradata_size > 0);
    
    ret = [self __extradataAsAVCC:extradata
                             size:extradata_size
                              sps:buf_SPS
                              pps:buf_PPS];
    CBRA(ret);
    CBRA([buf_SPS length] > 0 && [buf_PPS length] > 0);
    
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
        
        FFMLOG_OC(@"READY [format: %@]", fmt);
    }
    
    // detach
    *avc_fmt = fmt;
    fmt = NULL;
    
ERROR:
    if (extradata && extradata != ctxCodec->extradata)
    {
        VBR(m_require_startcode2len);
        av_free(extradata);
        extradata = NULL;
    }
    
    if (fmt)
    {
        CFRelease(fmt);
        fmt = NULL;
    }
    
    return ret;
}

- (BOOL)__extradataAsAVCC:(uint8_t*)extradata
                     size:(int32_t)extradata_size
                      sps:(NSMutableData*)buf_SPS
                      pps:(NSMutableData*)buf_PPS
{
    BOOL ret = YES;
    
    uint8_t *cursor = NULL;
    AVC_DecoderConfigurationRecord *avc_decConfigRec = NULL;
    
    CBRA(extradata_size > sizeof(AVC_DecoderConfigurationRecord));
    
    avc_decConfigRec = (AVC_DecoderConfigurationRecord*)extradata;
    CPRA(avc_decConfigRec);
    CBRA(avc_decConfigRec->configurationVersion == 0x1);
    
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
        [buf_SPS appendBytes:cursor length:avc_sps_len];
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
        [buf_PPS appendBytes:cursor length:avc_pps_len];
        VBR([buf_PPS length] == avc_pps_len);
        
        // next set
        cursor += avc_pps_len;
    }
    
    CBRA((cursor - extradata) <= extradata_size);
    
ERROR:
    return ret;
}

- (BOOL)__extradataIsNALU:(const uint8_t*)extradata size:(int32_t)extradata_size
{
    BOOL ret = NO;
    
    if (extradata_size <= 4)
    {
        FINISH();
    }
    
    const uint8_t *p = extradata;
    
    // 00 00 00 01 or 00 00 01 ?
    if (p[0] != 0 || p[1] != 0)
    {
        FINISH();
    }
    
    if (p[2] == 0x1 || (p[2] == 0 && p[3] == 0x1))
    {
        ret = YES;
        FINISH();
    }
    
DONE:
    return ret;
}

- (int)__sampleBuf4packet:(AVPacket*)pkt
                codec_fmt:(CMFormatDescriptionRef)codec_fmt
                sampleBuf:(CMSampleBufferRef*)sampleBuf
{
    BOOL ret = YES;
    int err = ERR_SUCCESS;

    uint8_t *data_ptr = pkt->data;
    int32_t data_size = pkt->size;
    
    CMBlockBufferRef dataBlock = nil;
    CMSampleBufferRef sample = nil;
    
    CPRA(sampleBuf);
    
    // startcode to len if need
    if (m_require_startcode2len)
    {        
        AVIOContext *pb = NULL;
        err = avio_open_dyn_buf(&pb);
        CBRA(err == ERR_SUCCESS);
        
        ff_avc_parse_nal_units(pb, pkt->data, pkt->size);
        data_size = avio_close_dyn_buf(pb, &data_ptr);
        CBRA(data_size > 0);
        CPRA(data_ptr);
    }
    
    // block buffer
    err = CMBlockBufferCreateWithMemoryBlock(NULL,
                                             data_ptr,
                                             data_size,
                                             kCFAllocatorNull,
                                             NULL,
                                             0,
                                             data_size,
                                             0,
                                             &dataBlock);
    CBRA(err == kCMBlockBufferNoErr);
    CPRA(dataBlock);
    
    // dataBlock holds data_ptr now
    data_ptr = NULL;
    
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
    if (data_ptr && data_ptr != pkt->data)
    {
        av_free(data_ptr);
        data_ptr = NULL;
    }
    
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
    if (!yuv)
    {
        return NO;
    }
    
    @synchronized(self)
    {
        [m_pendingYUV addObject:yuv];
    }
    return YES;
}

- (REF_CLASS(VTBYUVBuffer))__popYUV
{
    REF_CLASS(VTBYUVBuffer) yuv = nil;
    
    @synchronized(self)
    {
        if ([m_pendingYUV count] < m_count4delayedPic)
        {
            FINISH();
        }
        
        yuv = (REF_CLASS(VTBYUVBuffer))[m_pendingYUV firstObject];
    
        for (REF_CLASS(VTBYUVBuffer) iter in m_pendingYUV)
        {
            CCBR(iter != yuv);
            
            if ([iter pts] < [yuv pts])
            {
                yuv = iter;
            }
        }
        
        if (yuv)
        {
            [m_pendingYUV removeObject:yuv];
        }
    }
    
DONE:
    return yuv;
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
    m_require_startcode2len = NO;
}

@end

@implementation DEF_CLASS(VTB_DECODE_FRAME_CONTEXT)

- (void)dealloc
{
}

@end
