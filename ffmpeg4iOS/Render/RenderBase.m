//
//  RenderBase.m
//  ffmpeg4iOS
//
//  Created by Wayne W. on 15/7/16.
//  Copyright (c) 2015年 github.com/henern. All rights reserved.
//

#import "RenderBase.h"
#import "ehm.h"

@interface DEF_CLASS(RenderBase) ()
{
    NSThread *m_render_thread;
    double m_last_pts;
}

@end

@implementation DEF_CLASS(RenderBase)

- (BOOL)drawFrame:(AVFrame *)avfDecoded enc:(AVCodecContext*)enc
{
    VBR(0);
    return NO;
}

- (BOOL)attachToView:(UIView *)view
{
    view.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
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
    
    self.aspectRatio = ratio;
    
    // spawn render thread
    m_render_thread = [[NSThread alloc] initWithTarget:self
                                              selector:@selector(__ffmpeg_rendering_thread:)
                                                object:nil];
    m_render_thread.name = [NSString stringWithFormat:@"ffmpeg4iOS.%@.Q.rendering", [self class]];
    [m_render_thread start];
    
ERROR:    
    if (!ret)
    {
        [self cleanup];
    }
    
    return ret;
}

- (BOOL)appendPacket:(AVPacket *)pkt
{
    NSMutableData *pkt_data = [NSMutableData dataWithBytes:(const void *)pkt
                                                    length:sizeof(*pkt)];
    [self performSelector:@selector(__recvPacket:)
                 onThread:m_render_thread
               withObject:pkt_data
            waitUntilDone:NO];
    
    return YES;
}

- (void)cleanup
{
    m_last_pts = 0.f;
    
    [m_render_thread cancel];
    m_render_thread = nil;
    
    [super cleanup];
    
    self.ref_codec = NULL;
    self.aspectRatio = 0.f;
}

#pragma mark private
- (void)__ffmpeg_rendering_thread:(id)param
{
    NSRunLoop *loop = [NSRunLoop currentRunLoop];
    
    // priority
    [NSThread setThreadPriority:1];
    
    while (1)
    {
        [loop run];
    }
}

- (BOOL)__recvPacket:(NSMutableData *)pkt_data
{
    VBR([NSThread currentThread] == m_render_thread);
    
    BOOL ret = YES;
    int err = ERR_SUCCESS;
    AVPacket *pkt = (AVPacket*)[pkt_data mutableBytes];
    
    int finished = 0;
    AVFrame *avfDecoded = av_frame_alloc();
    AVCodecContext *enc = [self ctx_codec];
    
    CPR(enc);
    CBRA(pkt_data.length == sizeof(AVPacket));
    
    err = avcodec_decode_video2(enc, avfDecoded, &finished, pkt);
    CBRA(err >= 0);
    
    // FIXME: render only supports YUV420P now
    CBRA(enc->pix_fmt == PIX_FMT_YUV420P);
    
    if (finished)
    {
        ret = [self __schedule_drawFrame:avfDecoded enc:enc];
        CBRA(ret);
    }
    
ERROR:
    if (avfDecoded)
    {
        av_frame_free(&avfDecoded);
        avfDecoded = NULL;
    }
    
    if (pkt)
    {
        av_free_packet(pkt);
        pkt = NULL;
    }
        
    return ret;
}

#define MS_PER_SEC      (1000000)
- (BOOL)__schedule_drawFrame:(AVFrame*)avf enc:(AVCodecContext*)enc
{
    BOOL ret = YES;
    double pts = AV_NOPTS_VALUE;
    
    AVFrame *avfDecoded = av_frame_alloc();
    CPRA(avfDecoded);
    
    av_frame_move_ref(avfDecoded, avf);
    
    // pts from ffmpeg
    pts = av_frame_get_best_effort_timestamp(avfDecoded);
    if (pts == AV_NOPTS_VALUE)
    {
        pts = 0.f;
    }
    
    // FIXME: avfDecoded->repeat_pict ?
    VBR(avfDecoded->repeat_pict == 0);
    
    // convert pts in second unit
    pts *= [self time_base];
    
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
    
    ret = [self drawFrame:avfDecoded enc:enc];
    CBRA(ret);
    
ERROR:
    if (avfDecoded)
    {
        av_frame_free(&avfDecoded);
        avfDecoded = NULL;
    }
    
    return ret;
}

@end
