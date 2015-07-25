//
//  ThreadSafeDebug.m
//  ffmpeg4iOS
//
//  Created by Wayne W on 15/7/25.
//  Copyright (c) 2015年 github.com/henern. All rights reserved.
//

#import "ThreadSafeDebug.h"

@implementation DEF_CLASS(ThreadSafeDebug)

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        self.host_thread = [NSThread currentThread];
    }
    
    return self;
}

- (BOOL)isInHostThread
{
    return [NSThread currentThread] == self.host_thread;
}

@end
