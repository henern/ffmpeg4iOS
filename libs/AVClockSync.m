//
//  AVClockSync.m
//  ffmpeg4iOS
//
//  Created by Wayne W on 15/7/22.
//  Copyright (c) 2015年 github.com/henern. All rights reserved.
//

#import "AVClockSync.h"
#import "ehm.h"
#import "libavutil/time.h"

@interface DEF_CLASS(AVClockSync) ()
@property (nonatomic, weak) REF_CLASS(AVStreamEngine) render_engine;
@property (nonatomic, weak) REF_CLASS(AVStreamEngine) audio_engine;
@property (atomic, assign) BOOL isEnabled;
@property (atomic, assign) int64_t clock_base;
@end

@implementation DEF_CLASS(AVClockSync)

- (instancetype)initWithVideo:(REF_CLASS(AVStreamEngine))render_engine
                        audio:(REF_CLASS(AVStreamEngine))audio_engine
{
    self = [super init];
    if (self)
    {
        self.render_engine = render_engine;
        self.audio_engine = audio_engine;
        
        self.option = AV_SYNC_DEFAULT_CLOCK;
    }
    
    return self;
}

- (double)timestamp
{
    if (!self.isEnabled)
    {
        VERROR();
        return 0.f;
    }
    
    REF_CLASS(AVStreamEngine) eng = self.audio_engine;      // prefer audio
    
    if (eng == nil || self.option != AV_SYNC_AUDIO_CLOCK)
    {
        // if audio is unavailable, use host clock, never use video. 
        return [self __host_sync_clock];
    }
    
    VPR(eng);
    return [eng timestamp];
}

- (void)start
{
    if (!self.isEnabled)
    {
        self.clock_base = av_gettime();
        self.isEnabled = YES;
    }
}

- (void)reset
{
    self.isEnabled = NO;
    self.clock_base = 0;
}

#pragma mark private
- (double)__host_sync_clock
{
    return (av_gettime() - self.clock_base) * 1.0f/ MS_PER_SEC;
}

@end
