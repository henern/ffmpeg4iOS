//
//  AudioEngine.h
//  ffmpeg4iOS
//
//  Created by Wayne W. on 15/7/16.
//  Copyright (c) 2015年 github.com/henern. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "libavformat/avformat.h"

@interface DEF_CLASS(AudioEngine) : NSObject

- (BOOL)attachTo:(AVStream*)stream err:(int*)errCode;

@end
