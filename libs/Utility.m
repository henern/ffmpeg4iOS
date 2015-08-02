//
//  Utility.m
//  ffmpeg4iOS
//
//  Created by Wayne W on 15/8/2.
//  Copyright (c) 2015年 github.com/henern. All rights reserved.
//

#import "Utility.h"
#import <UIKit/UIKit.h>

@implementation DEF_CLASS(Utility)

+ (float)iOSVersion
{
    NSString *ver = [[UIDevice currentDevice] systemVersion];
    return [ver floatValue];
}

@end
