//
//  Utility.h
//  ffmpeg4iOS
//
//  Created by Wayne W on 15/8/2.
//  Copyright (c) 2015年 github.com/henern. All rights reserved.
//

#import <Foundation/Foundation.h>

#define IOS8_OR_LATER()             ([DEF_CLASS(Utility) iOSVersion] >= 8.0)

@interface DEF_CLASS(Utility) : NSObject

+ (float)iOSVersion;

@end
