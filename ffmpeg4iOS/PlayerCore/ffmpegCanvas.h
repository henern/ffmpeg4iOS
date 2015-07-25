//
//  ffmpegCanvas.h
//  ffmpeg4iOS
//
//  Created by Wayne W on 15/7/25.
//  Copyright (c) 2015年 github.com/henern. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DEF_CLASS(ffmpegCanvas) : UIView

- (void)relayoutWithAspectRatio:(double)aspectRatio     // = width / height
                          width:(float)width
                         height:(float)height;

@end
