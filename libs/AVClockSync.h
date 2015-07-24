//
//  AVClockSync.h
//  ffmpeg4iOS
//
//  Created by Wayne W on 15/7/22.
//  Copyright (c) 2015年 github.com/henern. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AVStreamEngine.h"
#import "SyncCore.h"

typedef enum
{
    AV_SYNC_AUDIO_CLOCK         = 0,    // default
    AV_SYNC_VIDEO_CLOCK,                // not support yet
    AV_SYNC_HOST_CLOCK,                 // if audio is unavailable
    
    AV_SYNC_CLOCK_OPTION_MAX,
    
    AV_SYNC_DEFAULT_CLOCK       = AV_SYNC_AUDIO_CLOCK,
    
}AV_SYNC_CLOCK_OPTION;

@interface DEF_CLASS(AVClockSync) : NSObject <DEF_CLASS(SyncCore)>

@property (nonatomic, assign) AV_SYNC_CLOCK_OPTION option;

- (instancetype)initWithVideo:(REF_CLASS(AVStreamEngine))render_engine
                        audio:(REF_CLASS(AVStreamEngine))audio_engine;

- (void)start;
- (void)reset;

@end
