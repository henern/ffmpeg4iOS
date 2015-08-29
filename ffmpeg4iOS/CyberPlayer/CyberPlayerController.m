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

#pragma mark url
- (void)setContentString:(NSString *)contentString
{
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
    
    [self.view addSubview:m_playbackCore];
    
ERROR:
    return;
}

- (void)start
{
    [self play];
}

- (void)play
{
    [m_playbackCore play];
}

- (void)stop
{
    if (m_playbackCore)
    {
        [self pause];
        
        [m_playbackCore removeFromSuperview];
        m_playbackCore = nil;
    }
}

- (void)pause
{
    [m_playbackCore pause];
}

- (void)seekTo:(NSTimeInterval)newPos
{
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
    return m_playbackCore != nil;
}

- (CBPMoviePlaybackState)playbackState
{
    if (m_playbackCore)
    {
        return CBPMoviePlaybackStatePlaying;
    }
    
    return CBPMoviePlaybackStateStopped;
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
    VNOIMPL();
    return 0;
}

- (int)videoHeight
{
    VNOIMPL();
    return 0;
}

- (NSString *)getSDKVersion
{
    return @"0.1.0";
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

@end
