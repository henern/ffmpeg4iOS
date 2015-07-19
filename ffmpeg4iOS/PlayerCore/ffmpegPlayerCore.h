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

- (instancetype)initWithFrame:(CGRect)frame path:(NSString*)path4video;
- (NSString*)path;
- (NSError*)lastError;

- (void)play;
- (void)pause;
- (void)seekTo:(double)pos;

@end
