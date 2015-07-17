//
//  RenderBase.m
//  ffmpeg4iOS
//
//  Created by Wayne W. on 15/7/16.
//  Copyright (c) 2015年 github.com/henern. All rights reserved.
//

#import "RenderBase.h"
#import "ehm.h"

@implementation DEF_CLASS(RenderBase)

- (BOOL)attachTo:(AVStream*)stream err:(int*)errCode atIndex:(int)index
{
    BOOL ret = YES;
    AVCodecContext *enc = NULL;
    int err = ERR_SUCCESS;
    
    ret = [super attachTo:stream err:errCode atIndex:index];
    CBRA(ret);
        
    // aspect ratio
    float ratio = av_q2d(stream->codec->sample_aspect_ratio);
    if (!ratio)
    {
        ratio = av_q2d(stream->sample_aspect_ratio);
    }
    
    if (!ratio)
    {
        FFMLOG(@"No aspect ratio found, assuming 4:3");
        ratio = 4.0 / 3;
    }
    
    self.aspectRatio = ratio;
    
    // codec
    enc = stream->codec;
    CPRA(enc);
    
    AVCodec *codec = avcodec_find_decoder(enc->codec_id);
    CPRA(codec);
    
    err = avcodec_open2(enc, codec, NULL);
    CBRA(err >= ERR_SUCCESS);
    
ERROR:
    if (!ret && errCode)
    {
        *errCode = err;
    }
    
    if (!ret)
    {
        [self cleanup];
    }
    
    return ret;
}

- (void)cleanup
{
    [super cleanup];
        
    self.aspectRatio = 0.f;
}

@end
