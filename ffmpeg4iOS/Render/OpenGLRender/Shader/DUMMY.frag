static const char *fragmentShader = STRINGIFY(

uniform sampler2D videoFrameY;
varying lowp vec2 TexCoordOut;

void main(void)
{
    gl_FragColor = texture2D(videoFrameY, TexCoordOut);
}

);