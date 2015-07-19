static const char *vertexShader = STRINGIFY(

attribute vec4 position; 
//uniform float translate;
attribute vec2 TexCoordIn; 
varying vec2 TexCoordOut; 

void main(void)
{
    gl_Position = position; 
    TexCoordOut = TexCoordIn;
}

);