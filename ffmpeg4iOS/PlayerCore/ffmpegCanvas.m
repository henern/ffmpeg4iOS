//
//  ffmpegCanvas.m
//  ffmpeg4iOS
//
//  Created by Wayne W on 15/7/25.
//  Copyright (c) 2015年 github.com/henern. All rights reserved.
//

#import "ffmpegCanvas.h"
#import "RenderBase+Factory.h"
#import "ehm.h"

@implementation DEF_CLASS(ffmpegCanvas)

+ (Class)layerClass
{
    return [DEF_CLASS(RenderBase) renderLayerClass];
}

- (void)relayoutWithAspectRatio:(double)aspectRatio
                          width:(float)width
                         height:(float)height
{
    CGRect frame = self.frame;
    if (aspectRatio <= 0.f)
    {
        frame.origin.x = 0.f;
        frame.origin.y = 0.f;
        frame.size.width = width;
        frame.size.height = height;
        FINISH();
    }
    
    float blank = 0.f;
    if (width / height < aspectRatio)
    {
        blank = ceil((height - width / aspectRatio) / 2);
        
        frame.origin.x = 0.f;
        frame.origin.y = blank;
        frame.size.width = width;
        frame.size.height = height - blank * 2;
    }
    else
    {
        blank = ceil((width - height * aspectRatio) / 2);
        
        frame.origin.x = blank;
        frame.origin.y = 0.f;
        frame.size.width = width - blank * 2;
        frame.size.height = height;
    }
    
DONE:
    FFMLOG_OC(@"relayout to [%f, %f, %f, %f], aspect-ratio %lf",
              frame.origin.x, frame.origin.y, frame.size.width, frame.size.height,
              aspectRatio);
    
    self.frame = frame;
    return;
}

@end
