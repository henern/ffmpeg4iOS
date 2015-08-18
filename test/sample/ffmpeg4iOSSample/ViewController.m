//
//  ViewController.m
//  ffmpegTest
//
//  Created by Wayne W on 15/7/19.
//  Copyright (c) 2015年 github.com/henern. All rights reserved.
//

#import "ViewController.h"
#import <ffmpeg4iOS/ffmpegPlayerCore.h>

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
#if 1
    NSString *path = [[NSBundle mainBundle] pathForResource:@"T-ara.1080P.mv" ofType:@"rmvb"];
#else
    // FIXME: buggy audio in this mkv
    NSString *path = [[NSBundle mainBundle] pathForResource:@"老男孩" ofType:@"mkv"];
#endif
    
#if 0
    path = [[NSBundle mainBundle] pathForResource:@"Gangnam" ofType:@"mp4"];
#endif
    
    screen = [[DEF_CLASS(ffmpegPlayerCore) alloc] initWithFrame:self.view.bounds
                                                           path:path
                                                       autoPlay:YES];
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
