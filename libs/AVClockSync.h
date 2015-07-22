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

@interface DEF_CLASS(AVClockSync) : NSObject <DEF_CLASS(SyncCore)>

- (instancetype)initWithVideo:(REF_CLASS(AVStreamEngine))render_engine
                        audio:(REF_CLASS(AVStreamEngine))audio_engine;

@end
