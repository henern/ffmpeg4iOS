//
//  AVClockSync.m
//  ffmpeg4iOS
//
//  Created by Wayne W on 15/7/22.
//  Copyright (c) 2015年 github.com/henern. All rights reserved.
//

#import "AVClockSync.h"
#import "ehm.h"

@interface DEF_CLASS(AVClockSync) ()
@property (nonatomic, weak) REF_CLASS(AVStreamEngine) render_engine;
@property (nonatomic, weak) REF_CLASS(AVStreamEngine) audio_engine;
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
    }
    
    return self;
}

- (double)timestamp
{
    REF_CLASS(AVStreamEngine) eng = self.audio_engine;      // prefer audio
    
    if (eng == nil)
    {
        eng = self.render_engine;
    }
    
    VPR(eng);
    return [eng timestamp];
}

@end
