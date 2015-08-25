//
//  ffmpegPlayerCore.m
//  ffmpeg4iOS
//
//  Created by Wayne W. on 15/7/16.
//  Copyright (c) 2015年 github.com/henern. All rights reserved.
//

#import "ffmpegPlayerCore.h"
#import "ehm.h"
#import "ff_api.key"
#import "libavcodec/avcodec.h"
#import "libavdevice/avdevice.h"
#import "libavformat/avio.h"
#import "libswscale/swscale.h"
#import "RenderBase+Factory.h"
#import "AudioEngine+Factory.h"
#import "AVClockSync.h"
#import "ffmpegCanvas.h"

#define DEFAULT_STREAM          (-1)

@interface DEF_CLASS(ffmpegPlayerCore) ()
{
    BOOL m_shouldSeek;
    float m_pendingSeekTo;
    
    REF_CLASS(ffmpegCanvas) m_canvas;
}

@property (nonatomic, strong) NSThread *m_ffmpegQueue;
@property (nonatomic, copy) NSString *m_path4video;
@property (nonatomic, strong) NSError *m_err;

@property (atomic, assign) double duration;
@property (atomic, assign) double position;
@property (atomic, assign) float aspectRatio;   // = width / height
@property (atomic, assign) BOOL userPause;

@property (nonatomic, copy) NSString *m_httpHeader;
@property (nonatomic, copy) NSString *m_userAgent;

@end

@implementation DEF_CLASS(ffmpegPlayerCore)

#pragma mark setup
+ (void)initialize
{
    [super initialize];
    
    // verify
    CALL_FUNC(ff_verify_api_key)();
    
    // register ffmpeg once
    av_register_all();
    
    // init network component
    avformat_network_init();
}

- (instancetype)initWithFrame:(CGRect)frame
                         path:(NSString *)path4video
                     autoPlay:(BOOL)isAutoPlay
                   httpHeader:(NSString *)httpHeader
                    userAgent:(NSString *)userAgent
{
    VMAINTHREAD();
    
    self = [super initWithFrame:frame];
    if (self)
    {
        VPR(path4video);
        self.m_path4video = path4video;
        self.userPause = !isAutoPlay;
        
        self.m_httpHeader = httpHeader;
        self.m_userAgent = userAgent;
        
        m_canvas = [[DEF_CLASS(ffmpegCanvas) alloc] initWithFrame:self.bounds];
        [self addSubview:m_canvas];
        
        [self __setup];
    }
    
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    [m_canvas relayoutWithAspectRatio:self.aspectRatio
                                width:self.frame.size.width
                               height:self.frame.size.height];
}

- (void)dealloc
{
    [self __cleanup];
}

- (void)__setup
{
    VMAINTHREAD();
    
    [self __cleanup];
    
    self.m_ffmpegQueue = [[NSThread alloc] initWithTarget:self
                                                 selector:@selector(__ffmpeg_packet_thread:)
                                                   object:self.m_path4video];
    self.m_ffmpegQueue.name = [NSString stringWithFormat:@"ffmpeg4iOS.%@.Q.packet", [self class]];
    [self.m_ffmpegQueue start];
}

- (void)__cleanup
{
    [self.m_ffmpegQueue cancel];
    self.m_ffmpegQueue = nil;
}

#pragma mark public
- (NSString*)path
{
    return self.m_path4video;
}

- (NSError*)lastError
{
    return self.m_err;
}

#pragma mark public.playback
- (void)play
{
    VMAINTHREAD();
    
    self.userPause = NO;
}

- (void)pause
{
    VMAINTHREAD();
    
    self.userPause = YES;
}

- (void)seekTo:(double)pos
{
    VMAINTHREAD();
    
    FFMLOG_OC(@"try to seek to %lf", pos);
    m_pendingSeekTo = pos;
    m_shouldSeek = YES;
}

#pragma mark loop
- (void)__ffmpeg_packet_thread:(NSString*)path
{
    BOOL ret = YES;
    
    @autoreleasepool
    {
    AVFormatContext *avfContext = NULL;
    int err = ERR_SUCCESS;
    const char *filename = NULL;
    
    REF_CLASS(RenderBase) render_engine = [DEF_CLASS(RenderBase) engine];
    REF_CLASS(AudioEngine) audio_engine = [DEF_CLASS(AudioEngine) engine];
    
    // clock-sync
    REF_CLASS(AVClockSync) syncCore = [[DEF_CLASS(AVClockSync) alloc] initWithVideo:render_engine
                                                                              audio:audio_engine];
    CPRA(syncCore);
    render_engine.ref_synccore = syncCore;
    audio_engine.ref_synccore = syncCore;
    
    CBRA([path isKindOfClass:[NSString class]]);
    
    // attach to view
    [render_engine attachToView:m_canvas];
        
    // c point to path
    filename = [path UTF8String];
    CPRA(filename);
    
    // prepare options
    AVDictionary *format_opts = NULL;
    if ([self.m_userAgent length] > 0)
    {
        av_dict_set(&format_opts, "user_agent", [self.m_userAgent cStringUsingEncoding:NSUTF8StringEncoding], 0);
    }
    if ([self.m_httpHeader length] > 0)
    {
        av_dict_set(&format_opts, "headers", [self.m_httpHeader cStringUsingEncoding:NSUTF8StringEncoding], 0);
    }

    // open the video stream
    AVDictionary **param_opts = format_opts? &format_opts : NULL;
#ifdef _USE_DEPRECATED_FFMPEG_METHODS
    err = av_open_input_file(&avfContext, filename, NULL, 0, NULL);
#else
    err = avformat_open_input(&avfContext, filename, NULL, param_opts);
#endif
    CBRA(err == ERR_SUCCESS);
    FFMLOG(@"Opened stream");
    
    // free options
    if (format_opts)
    {
        av_dict_free(&format_opts);
        format_opts = NULL;
    }
        
    // find info
    err = avformat_find_stream_info(avfContext, NULL);
    CBRA(err >= ERR_SUCCESS);
    FFMLOG(@"Found stream info");
    
    // duration
    CBRA(avfContext->duration > 0);
    self.duration = avfContext->duration * 1.0f / AV_TIME_BASE;
    self.position = 0.f;
    FFMLOG_OC(@"[%@] duration is %lf", path, self.duration);
    
    // go through each streams
    for(int i = 0; i < avfContext->nb_streams; i++)
    {
        AVCodecContext *enc = avfContext->streams[i]->codec;
        avfContext->streams[i]->discard = AVDISCARD_ALL;
        
        switch(enc->codec_type)
        {
            case CODEC_TYPE_VIDEO:
            {
                ret = [render_engine attachTo:avfContext->streams[i] err:&err atIndex:i];
                break;
            }
            case CODEC_TYPE_AUDIO:
            {
                ret = [audio_engine attachTo:avfContext->streams[i] err:&err atIndex:i];
                break;
            }
            default:
                break;
        }
    }
    CBRA(ret);
    
    // relayout the canvas because of aspect-ratio changed
    self.aspectRatio = render_engine.aspectRatio;
    [self __force_relayout];
    
    // loop to consume the packets
    while (1)
    {
        @autoreleasepool
        {
        
        if (m_shouldSeek)
        {
            err = av_seek_frame(avfContext, DEFAULT_STREAM, m_pendingSeekTo * AV_TIME_BASE, 0);
            if (err < ERR_SUCCESS)
            {
                // just ignore
                FFMLOG(@"ERROR (%d) while trying to seek #%f", err, m_pendingSeekTo);
            }
            else
            {
                ret = [render_engine reset];
                CBRA(ret);
                
                ret = [audio_engine reset];
                CBRA(ret);
            }
            
            m_shouldSeek = NO;
            m_pendingSeekTo = 0.f;
        }
        
        // enable the clock
        [syncCore start];
        
        // recv the packet from ffmpeg
        [self __sync_readPacket4context:avfContext render:render_engine audio:audio_engine];
        
        // aspect-ratio may change
        if ([render_engine aspectRatio] != self.aspectRatio)
        {
            self.aspectRatio = [render_engine aspectRatio];
            [self __force_relayout];
        }
            
        // play or pause?
        if (self.userPause)
        {
            [audio_engine pause];
            [render_engine pause];
        }
        else
        {
            [audio_engine play];
            [render_engine play];
        }
        
        // FIXME: need to figure out where is good to update the position
        self.position = [syncCore timestamp];
            
        }
    }
    
ERROR:
    if (!ret)
    {
        [self __reportError:err note:nil];
    }
    
DONE:
    if (avfContext)
    {
        avformat_close_input(&avfContext);
        avfContext = NULL;
    }
    }
    
    return;
}

#pragma mark private
- (void)__reportError:(int)errCode note:(NSString*)note
{
    NSDictionary *usrInf = nil;
    if (note)
    {
        usrInf = [NSDictionary dictionaryWithObject:note forKey:@"description"];
    }
    
    NSError *err = [NSError errorWithDomain:FFMPEG4IOS_ERR_DOMAIN
                                       code:errCode
                                   userInfo:usrInf];
    
    DEF_WEAK_SELF();
    dispatch_async(dispatch_get_main_queue(), ^{
        
        weak_self.m_err = err;
    });
    
    FFMLOG(@"ERROR CODE:%d, %@", errCode, note);
}

- (void)__sync_readPacket4context:(AVFormatContext*)avfContext
                           render:(REF_CLASS(RenderBase))render_egine
                            audio:(REF_CLASS(AudioEngine))audio_engine
{
    VBR([NSThread currentThread] == self.m_ffmpegQueue);
    
    BOOL ret = YES;
    AVPacket packet = {0};
    int err = ERR_SUCCESS;
    
    while (1)
    {
        // if both video and audio is full of packets
        if ([render_egine isFull] && [audio_engine isFull])
        {
            // take a break to reduce CPU usage (130% ==> 40%).
            // VLC is far more better (19% vs 40%), for the same video sample.
            usleep(MS_PER_SEC * 0.5);
            break;
        }
        
        @autoreleasepool
        {
        
        err = av_read_frame(avfContext, &packet);
        if (err != ERR_SUCCESS)
        {
            if (err == AVERROR(EAGAIN) && avfContext->pb->error == AVERROR(EAGAIN))
            {
                avfContext->pb->eof_reached = 0;
                avfContext->pb->error = 0;
            }
            
            break;
        }
        
        if (avfContext->pb->eof_reached &&
            avfContext->pb->error == AVERROR(EAGAIN))
        {
            avfContext->pb->eof_reached = 0;
            avfContext->pb->error = 0;
        }
        
        // unable to handle, discard
        if (![render_egine canHandlePacket:&packet] &&
            ![audio_engine canHandlePacket:&packet])
        {
            av_free_packet(&packet);
            continue;
        }
        
        // check the header
        err = av_dup_packet(&packet);
        CCBRA(err >= ERR_SUCCESS);
        
        // push to target engine
        if ([render_egine canHandlePacket:&packet])
        {
            ret = [render_egine appendPacket:&packet];
        }
        else if ([audio_engine canHandlePacket:&packet])
        {
            ret = [audio_engine appendPacket:&packet];
        }
        else
        {
            VBR(0);
            ret = NO;
            
            av_free_packet(&packet);
        }
        CCBRA(ret);
        
        break;
            
        }
    }
    
ERROR:
    return;
}

- (void)__force_relayout
{
    if ([NSThread isMainThread])
    {
        [self setNeedsLayout];
    }
    else
    {
        VBR([NSThread currentThread] == self.m_ffmpegQueue);
        
        dispatch_sync(dispatch_get_main_queue(), ^{
           
            [self setNeedsLayout];
        });
    }
}

@end
