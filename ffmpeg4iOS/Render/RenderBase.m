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

- (BOOL)attachToView:(UIView *)view
{
    view.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    self.ref_drawingView = view;
    
    return ([self.ref_drawingView isKindOfClass:[UIView class]]);
}

- (BOOL)attachTo:(AVStream*)stream err:(int*)errCode atIndex:(int)index
{
    BOOL ret = YES;
    AVCodecContext *enc = NULL;
    AVCodec *codec = NULL;
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
    
    codec = avcodec_find_decoder(enc->codec_id);
    CPRA(codec);
    
    // MUST copy the ctx?
    err = avcodec_open2(enc, codec, NULL);
    CBRA(err >= ERR_SUCCESS);
    
    // keep ref
    self.ref_codec = codec;
    
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
    
    self.ref_codec = NULL;
    self.aspectRatio = 0.f;
}

@end
