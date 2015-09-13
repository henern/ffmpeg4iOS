//
//  ViewController.m
//  ffmpegTest
//
//  Created by Wayne W on 15/7/19.
//  Copyright (c) 2015年 github.com/henern. All rights reserved.
//

#import "ViewController.h"
#import <ffmpeg4iOS/ffmpegPlayerCore.h>

// local test cases
#define __RMVB_RV40_COOK__          0
#define __MKV_H264_VORBIS__         0
#define __MP4_H264_AACLOW__         0

// online test cases
#define __TS_H264_HEACC__           1
#define __DMF_DX50_MP3__            0
#define __WEBM_VP8_VORB__           0
#define __3GP_H263_SAMR__           0
#define __OGG_THEO_VORB__           0
#define __FLV_FLV1_MP3__            0
#define __MP4_H264_AACLOW_HTTPS__   1

@interface ViewController ()
{
    UITextView *textView_info;
    UITextView *textView_seek;
    UIButton *button_seek;
    UIButton *button_play;
    UIButton *button_pause;
    
    REF_CLASS(ffmpegPlayerCore) screen;
}
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    // path to video resource
    NSString *path = nil;
    
#if __RMVB_RV40_COOK__
    path = [[NSBundle mainBundle] pathForResource:@"T-ara.1080P.mv" ofType:@"rmvb"];
#endif
    
#if __MKV_H264_VORBIS__
    // FIXME: buggy audio in this mkv
    path = [[NSBundle mainBundle] pathForResource:@"老男孩" ofType:@"mkv"];
#endif
    
#if __MP4_H264_AACLOW__
    path = [[NSBundle mainBundle] pathForResource:@"Opera.480p.x264.AAC" ofType:@"mp4"];
#endif
    
#if __TS_H264_HEACC__
    // online resource, may be expired
    path = @"http://v.ku6.com/fetchwebm/ahl6SyvG-AUCIys8UlIcjg...m3u8";
#endif
    
#if __DMF_DX50_MP3__
    path = @"http://trailers.divx.com/divx_prod/profiles/Helicopter_DivXHT_ASP.divx";
#endif
    
#if __WEBM_VP8_VORB__
    path = @"http://techslides.com/demos/sample-videos/small.webm";
#endif
    
#if __3GP_H263_SAMR__
    path = @"http://techslides.com/demos/sample-videos/small.3gp";
#endif
    
#if __OGG_THEO_VORB__
    path = @"http://techslides.com/demos/sample-videos/small.ogv";
#endif
    
#if __FLV_FLV1_MP3__
    path = @"http://techslides.com/demos/sample-videos/small.flv";
#endif
    
#if __MP4_H264_AACLOW_HTTPS__
    path = @"https://raw.githubusercontent.com/henern/ffmpeg4iOS/master/test/resources/Opera.480p.x264.AAC.mp4";
#endif
    
    screen = [[DEF_CLASS(ffmpegPlayerCore) alloc] initWithFrame:self.view.bounds
                                                           path:path
                                                       autoPlay:YES
                                                     httpHeader:@"Refer: www.github.com/henern\r\n"
                                                      userAgent:@"Mozilla/5.0 (iPhone; CPU iPhone OS 8_4 like Mac OS X) AppleWebKit/600.1.4 (KHTML, like Gecko) Version/8.0 Mobile/12H141 Safari/600.1.4"];
    screen.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    screen.backgroundColor = [UIColor grayColor];
    [self.view addSubview:screen];
    
    textView_seek = [[UITextView alloc] initWithFrame:CGRectMake(0, 20, self.view.frame.size.width, 30)];
    textView_seek.textAlignment = NSTextAlignmentCenter;
    textView_seek.textColor = [UIColor whiteColor];
    textView_seek.backgroundColor = [UIColor clearColor];
    textView_seek.font = [UIFont systemFontOfSize:18.f];
    textView_seek.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    textView_seek.text = @"105";
    [self.view addSubview:textView_seek];
    
    button_seek = [UIButton buttonWithType:UIButtonTypeCustom];
    [button_seek setTitle:@"SEEK" forState:UIControlStateNormal];
    button_seek.frame = CGRectMake(0, 60, self.view.frame.size.width, 30);
    button_seek.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [button_seek addTarget:self action:@selector(doSeek:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:button_seek];
    
    button_play = [UIButton buttonWithType:UIButtonTypeCustom];
    [button_play setTitle:@"PLAY" forState:UIControlStateNormal];
    button_play.frame = CGRectMake(0, 90, self.view.frame.size.width, 30);
    button_play.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [button_play addTarget:self action:@selector(doPlay:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:button_play];
    
    button_pause = [UIButton buttonWithType:UIButtonTypeCustom];
    [button_pause setTitle:@"PAUSE" forState:UIControlStateNormal];
    button_pause.frame = CGRectMake(0, 120, self.view.frame.size.width, 30);
    button_pause.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [button_pause addTarget:self action:@selector(doPause:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:button_pause];
    
    textView_info = [[UITextView alloc] initWithFrame:CGRectMake(0, 150, self.view.frame.size.width, 30)];
    textView_info.textAlignment = NSTextAlignmentCenter;
    textView_info.textColor = [UIColor whiteColor];
    textView_info.backgroundColor = [UIColor clearColor];
    textView_info.font = [UIFont systemFontOfSize:18.f];
    textView_info.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    textView_info.text = @"pos / duration";
    textView_info.editable = NO;
    [self.view addSubview:textView_info];
    
    [NSTimer scheduledTimerWithTimeInterval:1.f
                                     target:self
                                   selector:@selector(refreshInfo:)
                                   userInfo:nil
                                    repeats:YES];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)doSeek:(id)sender
{
    double pos = [textView_seek.text doubleValue];
    if (pos >= 0.f)
    {
        [textView_seek resignFirstResponder];
        [screen seekTo:pos];
    }
}

- (void)doPlay:(id)sender
{
    [screen play];
}

- (void)doPause:(id)sender
{
    [screen pause];
}

- (void)refreshInfo:(id)param
{
    NSString *inf = [NSString stringWithFormat:@"%lf / %lf", screen.position, screen.duration];
    [textView_info setText:inf];
}

@end
