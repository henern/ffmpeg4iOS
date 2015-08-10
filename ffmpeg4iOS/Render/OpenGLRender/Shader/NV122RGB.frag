static const char *nv12_fragment_shdr = STRINGIFY(
                                              
varying lowp vec2 TexCoordOut;
                                                  
uniform sampler2D videoFrameY;
uniform sampler2D videoFrameUV;
uniform mediump mat3 matColorConversion;        // precision is mandotary

void main(void)
{
    mediump vec3 yuv;
    lowp vec3 rgb;
    
    // Subtract constants to map the video range start at 0
    yuv.x  = texture2D(videoFrameY, TexCoordOut).r - (16.0/255.0);
    yuv.yz = texture2D(videoFrameUV, TexCoordOut).rg - vec2(0.5, 0.5);
    rgb    = matColorConversion * yuv;
    gl_FragColor = vec4(rgb, 1);
}

);

// BT.709, which is the standard for HDTV.
static const GLfloat kColorConversion709[] = {
    1.164,  1.164,  1.164,
    0.0,   -0.213,  2.112,
    1.793, -0.533,  0.0,
};
