//
//  VTBVideoDecode.h
//  ffmpeg4iOS
//
//  Created by Wayne W on 15/8/2.
//  Copyright (c) 2015年 github.com/henern. All rights reserved.
//

#import "ffmpegVideoDecode.h"

@interface DEF_CLASS(VTBVideoDecode) : DEF_CLASS(ffmpegVideoDecode)

@end

@interface DEF_CLASS(VTB_DECODE_FRAME_CONTEXT) : NSObject
@property (nonatomic, assign) int64_t pts;
@property (nonatomic, weak)   REF_CLASS(VTBVideoDecode) vtb;
@end
