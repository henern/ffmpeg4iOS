static const char *fragmentShader = STRINGIFY(

uniform sampler2D videoFrameY; 
uniform sampler2D videoFrameU;
uniform sampler2D videoFrameV;

varying lowp vec2 TexCoordOut;

void main(void)
{
    mediump vec3 yuv;
    lowp vec3 rgb;
    
    yuv.x = texture2D(videoFrameY, TexCoordOut).r;
    yuv.y = texture2D(videoFrameU, TexCoordOut).r - 0.5;
    yuv.z = texture2D(videoFrameV, TexCoordOut).r - 0.5;
    
    rgb = mat3( 1,       1,         1,
                0,       -0.39465,  2.03211,
                1.13983, -0.58060,  0) * yuv;
    
    gl_FragColor = vec4(rgb, 1);
}

);
