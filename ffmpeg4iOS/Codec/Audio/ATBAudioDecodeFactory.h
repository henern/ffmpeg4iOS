//
//  ATBAudioDecodeFactory.h
//  ffmpeg4iOS
//
//  Created by Wayne W on 15/8/9.
//  Copyright (c) 2015年 github.com/henern. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ATBAudioDecode.h"

@interface DEF_CLASS(ATBAudioDecodeFactory) : NSObject

+ (id<DEF_CLASS(ATBAudioDecode)>)audioDecoder4codec:(AVCodecContext*)codec;

@end
