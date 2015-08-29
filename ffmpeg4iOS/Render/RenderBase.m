//
//  RenderBase.m
//  ffmpeg4iOS
//
//  Created by Wayne W. on 15/7/16.
//  Copyright (c) 2015年 github.com/henern. All rights reserved.
//

#import "RenderBase.h"
#import "ehm.h"
#import "ffmpegVideoDecode+Factory.h"

#define MAX_REORDERED_PKT_PTS       8
#define MAX_PENDING_YUV_IN_QUEUE    MAX_REORDERED_PKT_PTS

@interface DEF_CLASS(RenderBase) ()
{
    NSThread *m_render_thread;
    double m_last_pts;
    
    NSCondition *m_signal_thread_quit;
    
    REF_CLASS(ffmpegVideoDecode) m_decoder;
    int32_t m_count4pendingYUVs;    // how many YUVs pending to draw
}

@end

@implementation DEF_CLASS(RenderBase)

- (BOOL)drawYUV:(id<DEF_CLASS(YUVBuffer)>)yuvBuf enc:(AVCodecContext*)enc
{
    VRENDERTHREAD();
    m_last_pts = [yuvBuf pts] * [self time_base];
    return (m_last_pts >= 0.f);
}

- (BOOL)isInRenderThread
{
    return [NSThread currentThread] == m_render_thread;
}

- (BOOL)attachToView:(UIView *)view
{
    VHOSTTHREAD();
    
    self.ref_drawingView = view;
    
    return ([self.ref_drawingView isKindOfClass:[UIView class]]);
}

- (BOOL)attachTo:(AVStream*)stream err:(int*)errCode atIndex:(int)index
{
    BOOL ret = YES;
    
    ret = [super attachTo:stream err:errCode atIndex:index];
    CBRA(ret);
        
    // aspect ratio
    float ratio = av_q2d(stream->codec->sample_aspect_ratio);
    if (!ratio)
    {
        ratio = av_q2d(stream->sample_aspect_ratio);
    }
    
    if (!ratio)
    {
        FFMLOG(@"No aspect ratio found, assuming 4:3");
        ratio = 4.0 / 3;
    }
    else
    {
        ratio *= stream->codec->width * 1.f / stream->codec->height;
    }
    
    self.aspectRatio = ratio;
    
    // different codec, different decoder
    m_decoder = [DEF_CLASS(ffmpegVideoDecode) decoder4codec:[self ctx_codec]];
    CPRA(m_decoder);
    
    // spawn render thread
    ret = [self __setupRendering];
    CBRA(ret);
    
ERROR:    
    if (!ret)
    {
        [self cleanup];
    }
    
    return ret;
}

- (void)cleanup
{
    [self __destroyRenderingThread];
    
    [super cleanup];
    
    self.ref_codec = NULL;
    self.aspectRatio = 0.f;
    
    m_decoder = nil;
}

- (BOOL)reset
{
    [super reset];
    
    if (![self __setupRendering])
    {
        VERROR();
        return NO;
    }
    
    return YES;
}

- (BOOL)doPlay
{
    return YES;
}

- (BOOL)doPause
{
    return YES;
}

#pragma mark private
- (void)__ffmpeg_rendering_thread:(id)param
{
    // priority
    [NSThread setThreadPriority:1];
    
    VPR(m_signal_thread_quit);
    
    while (1)
    {
        @autoreleasepool
        {
        NSDate *nearFuture = [NSDate dateWithTimeIntervalSinceNow:0.5f];
        NSRunLoop *runloop = [NSRunLoop currentRunLoop];
        [runloop runUntilDate:nearFuture];
        
        // one or more packets are available
        BOOL shouldQuit = NO;
        BOOL ret = [self __handlePacketsIfQuit:&shouldQuit];
        UNUSE(ret);
        
        if (shouldQuit)
        {
            break;
        }
        }
    }
    
    // -[self __destroyRenderingThread] is wait for this
    SIGNAL_CONDITION(m_signal_thread_quit);
    
    FFMLOG(@"%@ quits", [NSThread currentThread].name);
}

- (BOOL)__handlePacketsIfQuit:(BOOL*)ifQuit
{
    VRENDERTHREAD();
    
    BOOL ret = YES;
    
    CPRA(ifQuit);
    *ifQuit = NO;
    
    while (1)
    {
        @autoreleasepool
        {
        // if there are too much pending YUV,
        // we should not consume any more packet now, because of the memory issue.
        if (m_count4pendingYUVs > MAX_PENDING_YUV_IN_QUEUE)
        {
            break;
        }
            
        AVPacket pkt = {0};
        AVPacket *top = [self topPacket];
        
        // try to check the top
        if (!top)
        {
            break;
        }
        
        // consume one
        ret = [self popPacket:&pkt];
        CCBRA(ret);
        
        // if quit, discard all pending
        if ([self __isQuitPacket:&pkt])
        {
            *ifQuit = YES;
            FINISH();
        }
        
        // drop the packet if error
        ret = [self __recvPacket:&pkt];
    DONE:
        if (pkt.data)
        {
            av_free_packet(&pkt);
        }
        CCBR(ret);
        }
    }

ERROR:
    return ret;
}

- (BOOL)__recvPacket:(AVPacket *)pkt
{
    VRENDERTHREAD();
    
    BOOL ret = YES;
    int err = ERR_SUCCESS;
    
    id<DEF_CLASS(YUVBuffer)> yuvBuf = nil;
    int finished = 0;
    AVCodecContext *enc = [self ctx_codec];
    
    CPRA(pkt);
    CBR([NSThread currentThread] == m_render_thread);   // discard if reset
    CPR(enc);
    
    // perf?
    err = [m_decoder decodePacket:pkt yuvBuffer:&yuvBuf codec:enc finished:&finished];
    CBR(err == ERR_SUCCESS);
    
    if (!finished)
    {
        // not finished yet, it's NOT error.
        FINISH();
    }
    CPRA(yuvBuf);
    
    // only supports YUV420P, 2VUY & NV12 now
    CBRA([yuvBuf pix_fmt] == AV_PIX_FMT_YUV420P ||
         [yuvBuf pix_fmt] == AV_PIX_FMT_NV12 ||
         [yuvBuf pix_fmt] == AV_PIX_FMT_UYVY422);
    
    if (finished)
    {
        ret = [self __schedule_drawYUV:yuvBuf enc:enc];
        CBRA(ret);
    }
    
DONE:
ERROR:
    return ret;
}

- (BOOL)__schedule_drawYUV:(id<DEF_CLASS(YUVBuffer)>)yuvBuf enc:(AVCodecContext*)enc
{
    VRENDERTHREAD();
    
    BOOL ret = YES;
    double pts = AV_NOPTS_VALUE;
    
    CPRA(yuvBuf);
    
    pts = [yuvBuf pts];
    if (pts == AV_NOPTS_VALUE)
    {
        pts = 0.f;
    }
    
    // FIXME: avfDecoded->repeat_pict ?
    VBR([yuvBuf repeat_pict] == 0);
    
    // convert pts in second unit
    pts *= [self time_base];
    
    // first frame?
    if (m_last_pts == AV_NOPTS_VALUE)
    {
        m_last_pts = pts;
    }
    
    // delay since previous frame
    double delay = pts - m_last_pts;
    if (delay < 0.f)
    {
        // drop
        FINISH();
    }
    
    // sync with sync-core
    delay = [self delay4pts:pts delayInPlan:delay];
    
    // delay for this frame
    ret = [self __delayDrawYUV:yuvBuf delay:delay];
    CBRA(ret);
    
DONE:
ERROR:
    return ret;
}

- (BOOL)__setupRendering
{
    VHOSTTHREAD();
    
    [self __destroyRenderingThread];
    
    m_signal_thread_quit = [[NSCondition alloc] init];
    VPR(m_signal_thread_quit);
    
    // spawn render thread
    m_render_thread = [[NSThread alloc] initWithTarget:self
                                              selector:@selector(__ffmpeg_rendering_thread:)
                                                object:nil];
    m_render_thread.name = [NSString stringWithFormat:@"ffmpeg4iOS.%@.Q.rendering", [self class]];
    [m_render_thread start];
    
    // now ready
    AVSE_STATUS_SET(AVSTREAM_ENGINE_STATUS_PREPARE);
    
    return [m_render_thread isExecuting];
}

- (void)__destroyRenderingThread
{
    VHOSTTHREAD();
    
    if (m_render_thread)
    {
        WAIT_CONDITION_BEGIN(m_signal_thread_quit);
        
        [self.pkt_queue reset];
        [self __appendQuitPacket];
        
        // block until the thread finished
        WAIT_CONDITION_END(m_signal_thread_quit);
    }
    
    m_signal_thread_quit = nil;
    
    m_render_thread = NULL;
    m_last_pts = AV_NOPTS_VALUE;
}

- (BOOL)__delayDrawYUV:(id<DEF_CLASS(YUVBuffer)>)yuvBuf delay:(double)delayInSec
{
    VRENDERTHREAD();
    
    BOOL ret = YES;
    
    m_count4pendingYUVs++;
    
    double threshold = 1.5f / av_q2d([self ctx_codec]->framerate);
    
    if (delayInSec > threshold)
    {
        [self performSelector:@selector(__impl_delayDrawYUV:)
                   withObject:yuvBuf
                   afterDelay:delayInSec];
        
        FINISH();
    }
    else if (delayInSec > 0.f)
    {
        usleep(delayInSec * MS_PER_SEC);
    }
    
    ret = [self __impl_delayDrawYUV:yuvBuf];
    CBRA(ret);
    
DONE:
ERROR:
    return ret;
}

- (BOOL)__impl_delayDrawYUV:(id<DEF_CLASS(YUVBuffer)>)yuvBuf
{
    VRENDERTHREAD();
    
    // aspect may be different from the one in codec
    VBR([yuvBuf width] > 0 && [yuvBuf height] > 0);
    float frame_aspect = 1.0 * [yuvBuf width] / [yuvBuf height];
    if (frame_aspect != self.aspectRatio)
    {
        self.aspectRatio = frame_aspect;
    }
    
    // count the pending YUV
    m_count4pendingYUVs--;
    VBR(m_count4pendingYUVs >= 0);
    
    AVCodecContext *enc = [self ctx_codec];
    
    BOOL ret = [self drawYUV:yuvBuf enc:enc];
    CBRA(ret);
    
ERROR:
    return ret;
}

#define AV_PKT_FLAG_QUIT        0x8000
- (BOOL)__isQuitPacket:(AVPacket*)pkt
{
    return ((pkt->flags & AV_PKT_FLAG_QUIT) != 0);
}

#define AVPACKET_QUIT_DATA      "av_packet_quit"
- (BOOL)__appendQuitPacket
{
    AVPacket pktQuit = {0};
    av_new_packet(&pktQuit, sizeof(AVPACKET_QUIT_DATA));
    pktQuit.flags |= AV_PKT_FLAG_QUIT;
    
    VBR(pktQuit.size == sizeof(AVPACKET_QUIT_DATA));
    VPR(pktQuit.data);
    memcpy(pktQuit.data, AVPACKET_QUIT_DATA, sizeof(AVPACKET_QUIT_DATA));
    
    return [self appendPacket:&pktQuit];
}

@end
