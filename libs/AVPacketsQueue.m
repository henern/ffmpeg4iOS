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
    int64_t m_queueSize;
    // FIXME: i don't think array is good choice here
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
    
    @synchronized(self)
    {
        m_queueSize += pkt->size;
        [m_queue addObject:[NSMutableData dataWithBytes:pkt length:sizeof(*pkt)]];
    }
    
ERROR:
    return ret;
}

- (AVPacket*)topPacket
{
    NSMutableData *iter = nil;
    
    @synchronized(self)
    {
        iter = [m_queue firstObject];
        VBR(!iter || iter.length == sizeof(AVPacket));
    }
    
    if (iter.length == sizeof(AVPacket))
    {
        return (AVPacket*)[iter bytes];
    }
    
    return NULL;
}

- (BOOL)popPacket:(AVPacket *)destPkt
{
    BOOL ret = YES;
    NSMutableData *iter = nil;
    
    CPRA(destPkt);
    CBR(m_queueSize > 0);
    CBRA([m_queue count] > 0);
    
    @synchronized(self)
    {
        AVPacket *pkt = NULL;
        iter = [m_queue firstObject];
        CPR(iter);
        CBRA(iter.length == sizeof(*destPkt));
        
        pkt = (AVPacket*)[iter bytes];
        CPRA(pkt);
        
        m_queueSize -= pkt->size;
        [m_queue removeObject:iter];
        CBRA(m_queueSize >= 0);
    }
    
    memcpy(destPkt, [iter bytes], sizeof(*destPkt));
    
ERROR:
    return ret;
}

- (BOOL)cleanup
{
    return [self reset];
}

- (BOOL)reset
{
    @synchronized(self)
    {
        for (NSMutableData *pktData in m_queue)
        {
            av_free_packet([pktData mutableBytes]);
        }
        
        [m_queue removeAllObjects];
        m_queueSize = 0;
    }
    
    return YES;
}

- (int64_t)totalSize
{
    return m_queueSize;
}

- (UInt32)length
{
    VBR(m_queue.count < UINT32_MAX);
    return (UInt32)m_queue.count;
}

@end
