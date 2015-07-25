//
//  ThreadSafeDebug.h
//  ffmpeg4iOS
//
//  Created by Wayne W on 15/7/25.
//  Copyright (c) 2015年 github.com/henern. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DEF_CLASS(ThreadSafeDebug) : NSObject

@property (atomic, weak) NSThread *host_thread;

- (BOOL)isInHostThread;

@end

#if DEBUG
#define THREADSAFE_DEBUG_CLASS      DEF_CLASS(ThreadSafeDebug)
#define VHOSTTHREAD()               VBR([self isInHostThread])
#else
#define THREADSAFE_DEBUG_CLASS      NSObject
#define VHOSTTHREAD()               
#endif