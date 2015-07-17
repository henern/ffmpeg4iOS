//
//  AVStreamEngine.m
//  ffmpeg4iOS
//
//  Created by Wayne W. on 15/7/17.
//  Copyright (c) 2015年 github.com/henern. All rights reserved.
//

#import "AVStreamEngine.h"

@implementation DEF_CLASS(AVStreamEngine)

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        self.pkt_queue = [[DEF_CLASS(AVPacketsQueue) alloc] init];
    }
    
    return self;
}

- (void)cleanup
{
    [self.pkt_queue reset];
    
    self.ref_stream = NULL;
    self.index_stream = 0;
}

- (BOOL)attachTo:(AVStream*)stream err:(int*)errCode atIndex:(int)index
{
    [self cleanup];
    
    // mode for discard
    stream->discard = AVDISCARD_NONE;   // AVDISCARD_DEFAULT
    
    // keep stream
    self.ref_stream = stream;
    self.index_stream = index;
    
    return (self.ref_stream != NULL && self.index_stream > 0);
}

- (BOOL)canHandlePacket:(AVPacket *)pkt
{
    return (self.index_stream > 0 && pkt->stream_index == self.index_stream);
}

- (BOOL)appendPacket:(AVPacket *)pkt
{
    return [self.pkt_queue appendPacket:pkt];
}

@end
