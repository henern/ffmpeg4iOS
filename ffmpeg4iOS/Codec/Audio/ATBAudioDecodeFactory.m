//
//  ATBAudioDecodeFactory.m
//  ffmpeg4iOS
//
//  Created by Wayne W on 15/8/9.
//  Copyright (c) 2015年 github.com/henern. All rights reserved.
//

#import "ATBAudioDecodeFactory.h"
#import "AQAudioDecode.h"
#import "ffmpegAudioDecode.h"

@implementation DEF_CLASS(ATBAudioDecodeFactory)

+ (id<DEF_CLASS(ATBAudioDecode)>)audioDecoder4codec:(AVCodecContext*)codec
{
    enum AVCodecID cid = codec->codec_id;
    if (CODEC_ID_MP3 == cid ||
        CODEC_ID_AAC == cid ||
        CODEC_ID_AC3 == cid)
    {
        return [[DEF_CLASS(AQAudioDecode) alloc] init];
    }
    
    return [[DEF_CLASS(ffmpegAudioDecode) alloc] init];
}

@end
