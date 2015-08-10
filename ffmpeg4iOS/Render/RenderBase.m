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

@interface DEF_CLASS(RenderBase) ()
{
    NSThread *m_render_thread;
    double m_last_pts;
    
    NSCondition *m_signal_packet_available;
    NSCondition *m_signal_thread_quit;
    
    REF_CLASS(ffmpegVideoDecode) m_decoder;
}

@end

@implementation DEF_CLASS(RenderBase)

- (BOOL)drawYUV:(id<DEF_CLASS(YUVBuffer)>)yuvBuf enc:(AVCodecContext*)enc
{
    VRENDERTHREAD();
    return YES;
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

- (BOOL)appendPacket:(AVPacket *)pkt
{
    VHOSTTHREAD();
    
    BOOL ret = [super appendPacket:pkt];
    CBRA(ret);
    
    // wake up __ffmpeg_rendering_thread
    VPR(m_signal_packet_available);
    SIGNAL_CONDITION(m_signal_packet_available);
    
ERROR:
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
    dispatch_async(dispatch_get_current_queue(), ^{
        
        // MUST signal the condition async, after status ==> PLAYING 
        SIGNAL_CONDITION(m_signal_packet_available);
    });
    
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
    
    VPR(m_signal_packet_available);
    VPR(m_signal_thread_quit);
    
    while (1)
    {
        @autoreleasepool
        {
        WAIT_CONDITION(m_signal_packet_available);
        
        // one or more packets are available
        BOOL shouldQuit = NO;
        BOOL ret = [self __handlePacketsIfQuit:&shouldQuit];
        VBR(ret);
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
    CPRA(yuvBuf);
    
    // only supports YUV420P & NV12 now
    CBRA([yuvBuf pix_fmt] == AV_PIX_FMT_YUV420P ||
         [yuvBuf pix_fmt] == AV_PIX_FMT_NV12);
    
    if (finished)
    {
        ret = [self __schedule_drawYUV:yuvBuf enc:enc];
        CBRA(ret);
    }
    
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
    if (delay > 0.f)
    {
        m_last_pts = pts;
    }
    else
    {
        delay = 0.01f;
    }
    VBR(delay > 0.f);
    
    // sync with sync-core
    delay = [self delay4pts:pts delayInPlan:delay];
    
    // delay for this frame
    if (delay > 0.f)
    {
        usleep(delay * MS_PER_SEC);
    }
    
    ret = [self drawYUV:yuvBuf enc:enc];
    CBRA(ret);
    
ERROR:
    return ret;
}

- (BOOL)__setupRendering
{
    VHOSTTHREAD();
    
    [self __destroyRenderingThread];
    
    m_signal_packet_available = [[NSCondition alloc] init];
    VPR(m_signal_packet_available);
    m_signal_thread_quit = [[NSCondition alloc] init];
    VPR(m_signal_thread_quit);
    
    // spawn render thread
    m_render_thread = [[NSThread alloc] initWithTarget:self
                                              selector:@selector(__ffmpeg_rendering_thread:)
                                                object:nil];
    m_render_thread.name = [NSString stringWithFormat:@"ffmpeg4iOS.%@.Q.rendering", [self class]];
    [m_render_thread start];
    
    // now ready
    AVSE_STATUS_UNSET(AVSTREAM_ENGINE_STATUS_PREPARE);
    
    return [m_render_thread isExecuting];
}

- (void)__destroyRenderingThread
{
    VHOSTTHREAD();
    
    if (m_render_thread)
    {
        [self.pkt_queue reset];
        [self __appendQuitPacket];
        
        // block until the thread finished
        WAIT_CONDITION(m_signal_thread_quit);
    }
    
    m_signal_thread_quit = nil;
    m_signal_packet_available = nil;
    
    m_render_thread = NULL;
    m_last_pts = AV_NOPTS_VALUE;
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
