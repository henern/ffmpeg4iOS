//
//  OpenGLRender.m
//  ffmpeg4iOS
//
//  Created by Wayne W. on 15/7/16.
//  Copyright (c) 2015年 github.com/henern. All rights reserved.
//

#import "OpenGLRender.h"
#import "ehm.h"

@interface DEF_CLASS(OpenGLRender) ()
{
    GLfloat points[8];
    GLfloat texturePoints[8];
}

@end

@implementation DEF_CLASS(OpenGLRender)

- (BOOL)attachTo:(AVStream*)stream err:(int*)errCode
{
    BOOL ret = [super attachTo:stream err:errCode];
    CBRA(ret);
    
    ret = [self __setup2stream:stream err:errCode];
    CBRA(ret);
    
ERROR:
    return ret;
}

- (BOOL)__setup2stream:(AVStream*)stream err:(int*)errCode
{
    BOOL ret = YES;
    
    if ((float)self.bounds.size.height / self.bounds.size.width > self.aspectRatio)
    {
        GLfloat blank = (self.bounds.size.height - self.bounds.size.width * self.aspectRatio) / 2;
        points[0] = self.bounds.size.width;
        points[1] = self.bounds.size.height - blank;
        points[2] = 0;
        points[3] = self.bounds.size.height - blank;
        points[4] = self.bounds.size.width;
        points[5] = blank;
        points[6] = 0;
        points[7] = blank;
    }
    else
    {
        GLfloat blank = (self.bounds.size.width - (float)self.bounds.size.height / self.aspectRatio) / 2;
        points[0] = self.bounds.size.width - blank;
        points[1] = self.bounds.size.height;
        points[2] = blank;
        points[3] = self.bounds.size.height;
        points[4] = self.bounds.size.width - blank;
        points[5] = 0;
        points[6] = blank;
        points[7] = 0;
    }
    
    texturePoints[0] = 0;
    texturePoints[1] = 0;
    texturePoints[2] = 0;
    texturePoints[3] = 1;
    texturePoints[4] = 1;
    texturePoints[5] = 0;
    texturePoints[6] = 1;
    texturePoints[7] = 1;
    
ERROR:
    return ret;
}

@end
