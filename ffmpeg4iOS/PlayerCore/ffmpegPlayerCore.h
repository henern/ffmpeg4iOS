//
//  ffmpegPlayerCore.h
//  ffmpeg4iOS
//
//  Created by Wayne W. on 15/7/16.
//  Copyright (c) 2015年 github.com/henern. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LibCommon.h"

#define FF_SUPPORT_KVO

typedef enum
{
    FFMPEGPLAYERCORE_ERROR_OK               = 0,
    
    // more?
    
    FFMPEGPLAYERCORE_ERROR_UNKNOWN          = 0x1FFF,
    
}FFMPEGPLAYERCORE_ERROR;

typedef enum
{
    FFMPEGPLAYERCORE_STATE_UNKNOWN          = 0x0000,
    FFMPEGPLAYERCORE_STATE_INIT             = 0x0001,
    FFMPEGPLAYERCORE_STATE_READY            = 0x0002,
    FFMPEGPLAYERCORE_STATE_PAUSED_BY_USER   = 0x0004,
    FFMPEGPLAYERCORE_STATE_BUFFERING        = 0x0008,
    
    FFMPEGPLAYERCORE_STATE_ERROR            = 0x1000,
    
}FFMPEGPLAYERCORE_STATE;

@interface DEF_CLASS(ffmpegPlayerCore) : UIView

@property (nonatomic, assign) FF_SUPPORT_KVO double position;
@property (nonatomic, assign) FF_SUPPORT_KVO double duration;
@property (nonatomic, assign) FF_SUPPORT_KVO int width4video;
@property (nonatomic, assign) FF_SUPPORT_KVO int height4video;
@property (nonatomic, assign) FF_SUPPORT_KVO FFMPEGPLAYERCORE_STATE state;

@property (nonatomic, assign, readonly) NSError *error;
@property (nonatomic, strong, readonly) NSString *version;

- (instancetype)initWithFrame:(CGRect)frame
                         path:(NSString*)path4video
                     autoPlay:(BOOL)isAutoPlay
                   httpHeader:(NSString*)httpHeader     // e.g. @"Refer: github.com/henern\r\nPragma: no-cache\r\nRetry-After: 120\r\n"
                    userAgent:(NSString*)userAgent;
- (NSString*)path;
- (NSError*)lastError;

- (void)destroy;
- (void)play;
- (void)pause;
- (void)seekTo:(double)pos;

@end
