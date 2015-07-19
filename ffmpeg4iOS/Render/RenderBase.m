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
        
ERROR:    
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
