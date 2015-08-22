//
//  ffmpegPlayerCore.h
//  ffmpeg4iOS
//
//  Created by Wayne W. on 15/7/16.
//  Copyright (c) 2015年 github.com/henern. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LibCommon.h"

@interface DEF_CLASS(ffmpegPlayerCore) : UIView

- (instancetype)initWithFrame:(CGRect)frame
                         path:(NSString*)path4video
                     autoPlay:(BOOL)isAutoPlay
                   httpHeader:(NSString*)httpHeader     // e.g. @"Refer: github.com/henern\r\nPragma: no-cache\r\nRetry-After: 120\r\n"
                    userAgent:(NSString*)userAgent;
- (NSString*)path;
- (NSError*)lastError;

- (void)play;
- (void)pause;
- (void)seekTo:(double)pos;
- (double)duration;
- (double)position;

@end
