static const char *uyvy_fragment_shdr = STRINGIFY(
                                                  
// UYVY == 2VUY
                                                  
varying lowp vec2 TexCoordOut;
                                                  
uniform sampler2D videoFrameY;      // UY
uniform sampler2D videoFrameUV;     // UYUV
                                                  
void main(void)
{
    mediump vec3 yuv;
    lowp vec3 rgb;
    
    yuv.x = texture2D(videoFrameY, TexCoordOut).g;
    yuv.y = texture2D(videoFrameUV, TexCoordOut).r - 0.5;
    yuv.z = texture2D(videoFrameUV, TexCoordOut).b - 0.5;
    
    // SDTV with BT.601
    rgb = mat3(1,       1,         1,
               0,       -0.39465,  2.03211,
               1.13983, -0.58060,  0) * yuv;
    
    gl_FragColor = vec4(rgb, 1);
}
                                                  
);
