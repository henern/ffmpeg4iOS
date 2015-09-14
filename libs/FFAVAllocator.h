//
//  FFAVAllocator.h
//  ffmpeg4iOS
//
//  Created by wangwei34 on 15/9/14.
//  Copyright (c) 2015年 github.com/henern. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DEF_CLASS(FFAVAllocator) : NSObject

+ (CFAllocatorRef)createInst;       // caller should CFRelease the ref

@end
