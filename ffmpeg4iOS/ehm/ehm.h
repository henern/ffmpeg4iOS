//
//  ehm.h
//  ffmpeg4iOS
//
//  Created by Wayne W. on 13-5-28.
//
//

#ifndef ffmpeg4iOS_ehm_h
#define ffmpeg4iOS_ehm_h

#define VBR(x)      NSAssert((x), @"ERROR")
#define VPR(p)      NSAssert(nil != (p), @"ERROR")

#define VGLERR()    NSAssert(GL_NO_ERROR == glGetError(), @"OGL ERROR")

#endif
