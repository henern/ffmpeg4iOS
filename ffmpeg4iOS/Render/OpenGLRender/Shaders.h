//
//  Shaders.h
//  ffmpeg4iOS
//
//  Created by Wayne W. on 13-5-28.
//
//

#ifndef ffmpeg4iOS_Shaders_h
#define ffmpeg4iOS_Shaders_h

#define STRINGIFY(a)    #a
#import "./Shader/YUV2RGB.frag"
#import "./Shader/YUV2RGB.vert"
#define FRAGMENT_SHADER     fragmentShader
#define VERTEX_SHADER       vertexShader

#import "./Shader/NV122RGB.frag"
#define NV12_FRAGMENT_SHDR  nv12_fragment_shdr
#define NV12_VERTEX_SHDR    vertexShader

#endif
