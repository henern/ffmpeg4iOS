//
//  RenderBase.h
//  ffmpeg4iOS
//
//  Created by Wayne W. on 15/7/16.
//  Copyright (c) 2015年 github.com/henern. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AVStreamEngine.h"

@interface DEF_CLASS(RenderBase) : DEF_CLASS(AVStreamEngine)

@property (nonatomic, assign) float aspectRatio;
@property (nonatomic, assign) CGRect bounds;
@property (nonatomic, weak) UIView *ref_drawingView;            // weak ref to UIView

- (BOOL)attachToView:(UIView*)view;
- (BOOL)drawFrame:(AVFrame *)avfDecoded enc:(AVCodecContext*)enc;
- (BOOL)isInRenderThread;

@end

#define VRENDERTHREAD()         VBR([self isInRenderThread])
