//
//  LibCommon.h
//  ffmpeg4iOS
//
//  Created by Wayne W. on 15/7/16.
//  Copyright (c) 2015年 github.com/henern. All rights reserved.
//

#ifndef ffmpeg4iOS_LibCommon_h
#define ffmpeg4iOS_LibCommon_h

// class
#define DEF_COMBINE(name, prefix)   prefix##name
#define DEF_CLASS(name)         DEF_COMBINE(name, WW /* prefix */)
#define REF_CLASS(name)         DEF_CLASS(name)*

// log
#if DEBUG
#define FFMLOG(...)             NSLog(__VA_ARGS__)
#else
#define FFMLOG(...)
#endif

// weak
#define DEF_WEAK_SELF()         __weak typeof(self) weak_self = self

#endif
