//
//  AVPacketsQueue.m
//  ffmpeg4iOS
//
//  Created by Wayne W. on 15/7/17.
//  Copyright (c) 2015年 github.com/henern. All rights reserved.
//

#import "AVPacketsQueue.h"
#import "ehm.h"

#define QUEUE_CAPACITY      16

@interface DEF_CLASS(AVPacketsQueue) ()
{
    UInt32 m_queueSize;
    NSMutableArray *m_queue;
}

@end

@implementation DEF_CLASS(AVPacketsQueue)

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        m_queue = [NSMutableArray arrayWithCapacity:QUEUE_CAPACITY];
        m_queueSize = 0;
    }
    
    return self;
}

- (BOOL)appendPacket:(AVPacket *)pkt
{
    BOOL ret = YES;
    
    CPRA(pkt);
    CBRA(pkt -> size > 0);
    
    // need a lock here?
    m_queueSize += pkt->size;
    [m_queue addObject:[NSMutableData dataWithBytes:pkt length:sizeof(*pkt)]];
    
ERROR:
    return ret;
}

- (BOOL)reset
{
    for (NSMutableData *pktData in m_queue)
    {
        av_free_packet([pktData mutableBytes]);
    }
    
    [m_queue removeAllObjects];
    m_queueSize = 0;
    
    return YES;
}

- (UInt32)totalSize
{
    return m_queueSize;
}

- (UInt32)length
{
    VBR(m_queue.count < UINT32_MAX);
    return (UInt32)m_queue.count;
}

@end
