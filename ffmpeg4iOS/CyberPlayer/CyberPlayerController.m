//
//  CyberPlayerController.m
//  ffmpeg4iOS
//
//  Created by Wayne W on 15/7/5.
//  Copyright (c) 2015年 github.com/henern. All rights reserved.
//

#import "CyberPlayerController.h"
#import "ehm.h"
#import "ffmpegPlayerCore.h"

#define KVO_STATE           @"state"
#define KVO_DURATION        @"duration"
#define KVO_POS             @"position"

NSString * const CyberPlayerLoadDidPreparedNotification             = @"CyberPlayerLoadDidPreparedNotification";
NSString * const CyberPlayerPlaybackDidFinishNotification           = @"CyberPlayerPlaybackDidFinishNotification";
NSString * const CyberPlayerStartCachingNotification                = @"CyberPlayerStartCachingNotification";
NSString * const CyberPlayerGotCachePercentNotification             = @"CyberPlayerGotCachePercentNotification";
NSString * const CyberPlayerPlaybackErrorNotification               = @"CyberPlayerPlaybackErrorNotification";
NSString * const CyberPlayerSeekingDidFinishNotification            = @"CyberPlayerSeekingDidFinishNotification";
NSString * const CyberPlayerPlaybackStateDidChangeNotification      = @"CyberPlayerPlaybackStateDidChangeNotification";
NSString * const CyberPlayerMeidaTypeAudioOnlyNotification          = @"CyberPlayerMeidaTypeAudioOnlyNotification";
NSString * const CyberPlayerGotNetworkBitrateNotification           = @"CyberPlayerGotNetworkBitrateNotification";

@interface CyberPlayerController ()
{
    REF_CLASS(ffmpegPlayerCore) m_playbackCore;
    
    FFMPEGPLAYERCORE_STATE m_state4core;
}

@property (nonatomic, copy) NSString *userAgent;
@property (nonatomic, copy) NSString *customHttpHeader;
@property (nonatomic, strong) UIView *view;

@end

@implementation CyberPlayerController

+ (void) setBAEAPIKey:(NSString*)ak SecretKey:(NSString*)sk
{
    
}

#pragma mark initialization
- (id)initWithContentURL:(NSURL *)url
{
    return [self initWithContentString:[url absoluteString]];
}

- (id)initWithContentString:(NSString *)url
{
    self = [self init];
    if (self)
    {
        self.contentString = url;
    }
    
    return self;
}

#define DEFAULT_VIEW_FRAME      CGRectMake(0, 0, 320, 240)
- (id)init
{
    self = [super init];
    if (self)
    {
        self.view = [[UIView alloc] initWithFrame:DEFAULT_VIEW_FRAME];
        self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    }
    
    return self;
}

- (void)dealloc
{
    [self stop];
}

#pragma mark url
- (void)setContentString:(NSString *)contentString
{
    VMAINTHREAD();
    
    self.contentURL = nil;
    
    _contentString = [contentString copy];
    if ([self.contentString length] > 0)
    {
        self.contentURL = [NSURL URLWithString:self.contentString];
    }
}

#pragma mark playback
- (void)prepareToPlay
{
    VMAINTHREAD();
    
    BOOL ret = YES;
    
    [self stop];
    
    CBRA([self.contentString length] > 0 && self.view);
    CBR(!m_playbackCore);
    
    m_playbackCore = [[DEF_CLASS(ffmpegPlayerCore) alloc] initWithFrame:self.view.bounds
                                                                   path:self.contentString
                                                               autoPlay:self.shouldAutoplay
                                                             httpHeader:self.customHttpHeader
                                                              userAgent:self.userAgent];
    m_playbackCore.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    CPRA(m_playbackCore);
    
    // add KVOs
    [m_playbackCore addObserver:self
                     forKeyPath:KVO_STATE
                        options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionInitial)
                        context:nil];
    [m_playbackCore addObserver:self
                     forKeyPath:KVO_DURATION
                        options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionInitial)
                        context:nil];
    [m_playbackCore addObserver:self
                     forKeyPath:KVO_POS
                        options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionInitial)
                        context:nil];
    
    [self.view addSubview:m_playbackCore];
    
    m_state4core = m_playbackCore.state;
    
ERROR:
    return;
}

- (void)start
{
    [self play];
}

- (void)play
{
    VMAINTHREAD();
    [m_playbackCore play];
}

- (void)stop
{
    VMAINTHREAD();
    
    if (m_playbackCore)
    {
        [self pause];
        
        // remove all KVOs
        [m_playbackCore removeObserver:self forKeyPath:KVO_STATE];
        [m_playbackCore removeObserver:self forKeyPath:KVO_DURATION];
        [m_playbackCore removeObserver:self forKeyPath:KVO_POS];
        
        [m_playbackCore destroy];
        
        [m_playbackCore removeFromSuperview];
        m_playbackCore = nil;
    }
}

- (void)pause
{
    VMAINTHREAD();
    [m_playbackCore pause];
}

- (void)seekTo:(NSTimeInterval)newPos
{
    VMAINTHREAD();
    VPR(m_playbackCore);
    [m_playbackCore seekTo:newPos];
}

#pragma mark properties
- (NSTimeInterval)duration
{
    return m_playbackCore.duration;
}

- (NSTimeInterval)playableDuration
{
    VNOIMPL();
    return 0.f;
}

- (NSTimeInterval)infoDuration
{
    VNOIMPL();
    return 0.f;
}

- (BOOL)isPreparedToPlay
{
    VMAINTHREAD();
    return (m_playbackCore.state & FFMPEGPLAYERCORE_STATE_READY) != 0;
}

- (CBPMoviePlaybackState)playbackState
{
    VMAINTHREAD();
    
    if (![self isPreparedToPlay])
    {
        return CBPMoviePlaybackStateStopped;
    }
    
    if (m_playbackCore.state & FFMPEGPLAYERCORE_STATE_ERROR)
    {
        return CBPMoviePlaybackStateInterrupted;
    }
    
    if (m_playbackCore.state & FFMPEGPLAYERCORE_STATE_PAUSED_BY_USER)
    {
        return CBPMoviePlaybackStatePaused;
    }
    
    return CBPMoviePlaybackStatePlaying;
}

- (float)downloadSpeed
{
    VNOIMPL();
    return 0.f;
}

- (CGSize)naturalSize
{
    VNOIMPL();
    return CGSizeZero;
}

- (int)videoWidth
{
    VMAINTHREAD();
    return m_playbackCore.width4video;
}

- (int)videoHeight
{
    VMAINTHREAD();
    return m_playbackCore.height4video;
}

- (NSString *)getSDKVersion
{
    VMAINTHREAD();
    return m_playbackCore.version;
}

- (void)setParametKey:(NSString*)parametKey
{
    VNOIMPL();
}

#pragma mark subtitles
- (void)setSubtitleVisibility:(int) isShow
{
    VNOIMPL();
}

- (void)setSubtitleColor:(int) iColor
{
    VNOIMPL();
}

- (void)setSubtitleFontScale:(float) fFontScale
{
    VNOIMPL();
}

- (void)setSubtitleAlignMethod:(int) iAlignMethod
{
    VNOIMPL();
}

- (void)manualSyncSubtitle:(int) mSec
{
    VNOIMPL();
}

- (void)setExtSubtitleFile:(NSString*)subFilePath
{
    VNOIMPL();
}

- (int)openExtSubtitleFile:(NSString*)subFilePath
{
    VNOIMPL();
}

#pragma mark KVOs
- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
    VMAINTHREAD();
    
    if ([keyPath isEqualToString:KVO_STATE])
    {
        [self __handleStateChanged:change];
    }
    else if ([keyPath isEqualToString:KVO_DURATION])
    {
        [self __handleDurationChanged:change];
    }
    else if ([keyPath isEqualToString:KVO_POS])
    {
        [self __handlePositionChanged:change];
    }
    else
    {
        [super observeValueForKeyPath:keyPath
                             ofObject:object
                               change:change
                              context:context];
    }
}

- (void)__handleStateChanged:(NSDictionary*)change
{
    if ([self isPreparedToPlay] &&
        (m_state4core & FFMPEGPLAYERCORE_STATE_READY) == 0)
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:CyberPlayerLoadDidPreparedNotification
                                                            object:self];
    }
    
    m_state4core = m_playbackCore.state;
}

- (void)__handleDurationChanged:(NSDictionary*)change
{
    // nothing yet
}

- (void)__handlePositionChanged:(NSDictionary*)change
{
    self.currentPlaybackTime = m_playbackCore.position;
}

@end
