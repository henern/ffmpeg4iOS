//
//  ffmpegPlayerCore.m
//  ffmpeg4iOS
//
//  Created by Wayne W. on 15/7/16.
//  Copyright (c) 2015年 github.com/henern. All rights reserved.
//

#import "ffmpegPlayerCore.h"
#import <QuartzCore/QuartzCore.h>
#import "RenderBase.h"
#import "AudioEngine.h"
#import "ehm.h"
#import "libavcodec/avcodec.h"
#import "libavdevice/avdevice.h"
#import "libavformat/avio.h"
#import "libswscale/swscale.h"

@interface DEF_CLASS(ffmpegPlayerCore) ()
@property (nonatomic, strong) REF_CLASS(RenderBase) m_render_engine;
@property (nonatomic, strong) REF_CLASS(AudioEngine) m_audio_engine;

@property (nonatomic, strong) NSThread *m_ffmpegQueue;
@property (nonatomic, copy) NSString *m_path4video;
@property (nonatomic, strong) NSError *m_err;

@end

@implementation DEF_CLASS(ffmpegPlayerCore)

+ (Class)layerClass
{
    return [CAEAGLLayer class];
}

#pragma mark setup
- (instancetype)initWithFrame:(CGRect)frame path:(NSString *)path4video
{
    self = [super initWithFrame:frame];
    if (self)
    {
        VPR(path4video);
        self.m_path4video = path4video;
        
        [self __setup];
    }
    
    return self;
}

- (void)dealloc
{
    [self __cleanup];
}

- (void)__setup
{
    [self __cleanup];
    
    self.m_ffmpegQueue = [[NSThread alloc] initWithTarget:self
                                                 selector:@selector(__ffmpeg_packet_thread:)
                                                   object:self.m_path4video];
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
    
}

- (void)pause
{
    
}

- (void)seekTo:(double)pos
{
    
}

#pragma mark loop
- (void)__ffmpeg_packet_thread:(NSString*)path
{
    BOOL ret = YES;
    
    AVFormatContext *avfContext = NULL;
    int err = ERR_SUCCESS;
    const char *filename = NULL;
    
    CBRA([path isKindOfClass:[NSString class]]);
    
    // priority
    [NSThread setThreadPriority:1];
    
    // c point to path
    filename = [path UTF8String];
    CPRA(filename);
    
    // register ffmpeg
    av_register_all();
    
    // open the video stream
#ifdef _USE_DEPRECATED_FFMPEG_METHODS
    err = av_open_input_file(&avfContext, filename, NULL, 0, NULL);
#else
    err = avformat_open_input(&avfContext, filename, NULL, NULL);
#endif
    CBRA(err == ERR_SUCCESS);
    FFMLOG(@"Opened stream");
    
    // find info
    err = avformat_find_stream_info(avfContext, NULL);
    CBRA(err >= ERR_SUCCESS);
    FFMLOG(@"Found stream info");
    
ERROR:
    [self __reportError:err note:nil];
    
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

@end
