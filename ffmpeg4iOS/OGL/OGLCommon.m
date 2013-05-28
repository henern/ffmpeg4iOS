//
//  OGLCommon.mm
//  ffmpeg4iOS
//
//  Created by Wayne W. on 13-5-28.
//
//

#import "OGLCommon.h"

#define TEX_COORD_MAX   1
const Vertex Vertices[4] = {
    // Front
    {{1, -1, 0},    {1, 0, 0, 1}, {TEX_COORD_MAX, 0}},
    {{1, 1, 0},     {0, 1, 0, 1}, {0, 0}},
    {{-1, 1, 0},    {0, 0, 1, 1}, {0, TEX_COORD_MAX}},
    {{-1, -1, 0},   {0, 0, 0, 1}, {TEX_COORD_MAX, TEX_COORD_MAX}},
};

const GLubyte Indices[6] = {
    // Front
    0, 1, 2,
    2, 3, 0,
};

