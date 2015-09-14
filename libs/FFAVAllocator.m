//
//  FFAVAllocator.m
//  ffmpeg4iOS
//
//  Created by wangwei34 on 15/9/14.
//  Copyright (c) 2015年 github.com/henern. All rights reserved.
//

#import "FFAVAllocator.h"
#import "libavformat/avc.h"

static void ff_CFAllocatorDeallocateCallBack(void *ptr, void *info)
{
    if (ptr)
    {
        av_free(ptr);
        ptr = NULL;
    }
}

@implementation DEF_CLASS(FFAVAllocator)

+ (CFAllocatorRef)createInst
{
    CFAllocatorContext ctx = {0};
    ctx.deallocate = ff_CFAllocatorDeallocateCallBack;  // ONLY support dealloc now
    return CFAllocatorCreate(NULL, &ctx);
}

@end
