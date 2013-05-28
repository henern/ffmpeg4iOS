//
//  OGLProgram.m
//  ffmpeg4iOS
//
//  Created by Wayne W. on 13-5-28.
//
//

#import "OGLProgram.h"
#import <OpenGLES/EAGLDrawable.h>
#import <QuartzCore/QuartzCore.h>

@interface OGLProgram ()
{
    GLuint _prgrmOGL;
}

- (GLuint)_buildWithFragShader:(const char *)aFrag vertexShader:(const char*)aVert;
- (GLuint)_buildShader:(const char *)source type:(GLenum)type;

@end

@implementation OGLProgram

- (id)initWithVertShader:(const char*)vertShdr fragShader:(const char*)fragShdr
{
    self = [super init];
    if (self)
    {        
        GLuint prgm = [self _buildWithFragShader:fragShdr vertexShader:vertShdr];
        if (!prgm)
        {
            VBR(0);
            self = nil;
        }
        else
        {
            _prgrmOGL = prgm;
        }
    }

    return self;
}

- (BOOL)activate
{
    if (!_prgrmOGL)
    {
        return NO;
    }
    
    glUseProgram(_prgrmOGL);
    
    if (GL_NO_ERROR == glGetError())
    {
        [self _initAttributes];
        [self _initUniforms];
        [self _initTextures];
    }
    
    return GL_NO_ERROR == glGetError();
}

- (BOOL)activateTexYUV4buffer:(const void *)bytes width:(GLsizei)width height:(GLsizei)height
{
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, self.texY);
    glUniform1i(self.uniformTexY, 0);
    glTexImage2D(GL_TEXTURE_2D,
                 0,
                 GL_LUMINANCE,
                 width, height,
                 0,
                 GL_LUMINANCE, GL_UNSIGNED_BYTE,
                 bytes);
    VGLERR();
    
    glActiveTexture(GL_TEXTURE1);
    glBindTexture(GL_TEXTURE_2D, self.texU);
    glUniform1i(self.uniformTexU, 1);
    glTexImage2D(GL_TEXTURE_2D,
                 0,
                 GL_LUMINANCE,
                 width/2, height/2,
                 0,
                 GL_LUMINANCE, GL_UNSIGNED_BYTE,
                 bytes + height * width);
    VGLERR();
    
    glActiveTexture(GL_TEXTURE2);
    glBindTexture(GL_TEXTURE_2D, self.texV);
    glUniform1i(self.uniformTexV, 2);
    glTexImage2D(GL_TEXTURE_2D,
                 0,
                 GL_LUMINANCE,
                 width/2, height/2,
                 0,
                 GL_LUMINANCE, GL_UNSIGNED_BYTE,
                 bytes + height * width * 5 / 4);
    VGLERR();
    
    glActiveTexture(GL_TEXTURE0);
    
    return GL_NO_ERROR == glGetError();
}

- (void)dealloc
{
    glDeleteTextures(1, &_texY);
    glDeleteTextures(1, &_texU);
    glDeleteTextures(1, &_texV);
}

#pragma mark private
- (GLuint)_buildWithFragShader:(const char *)aFrag vertexShader:(const char*)aVert
{
    GLuint shdrVert = [self _buildShader:aVert type:GL_VERTEX_SHADER];
    GLuint shdrFrag = [self _buildShader:aFrag type:GL_FRAGMENT_SHADER];
    
    GLuint prog = glCreateProgram();
    glAttachShader(prog, shdrVert);
    glAttachShader(prog, shdrFrag);
    glLinkProgram(prog);
    
    GLint ret;
    glGetProgramiv(prog, GL_LINK_STATUS, &ret);
    if (GL_FALSE == ret)
    {
        assert(0);
        exit(1);
    }
    
    return prog;
}

- (GLuint)_buildShader:(const char *)source type:(GLenum)type
{
    GLuint shdr = glCreateShader(type);
    glShaderSource(shdr, 1, &source, NULL);
    glCompileShader(shdr);
    
    GLint compileRet;
    glGetShaderiv(shdr, GL_COMPILE_STATUS, &compileRet);
    if (GL_FALSE == compileRet)
    {
        assert(0);
        exit(1);
    }
    
    return shdr;
}

- (void)_initAttributes
{
    // locate the position attribute, see vert shader
    self.slotPosition = glGetAttribLocation(_prgrmOGL, "position");
    VGLERR();
    glEnableVertexAttribArray(_slotPosition);
    VGLERR();
    
    // locate the TexCoordIn attribute, see vert shader
    self.slotTexCoordIn = glGetAttribLocation(_prgrmOGL, "TexCoordIn");
    VGLERR();
    glEnableVertexAttribArray(_slotTexCoordIn);
    VGLERR();
}

- (void)_initUniforms
{
    // locate the texture uniforms, see frag shader
    self.uniformTexY = glGetUniformLocation(_prgrmOGL, "videoFrameY");
    VGLERR();
    self.uniformTexU = glGetUniformLocation(_prgrmOGL, "videoFrameU");
    VGLERR();
    self.uniformTexV = glGetUniformLocation(_prgrmOGL, "videoFrameV");
    VGLERR();
}

- (BOOL)_initTextures
{
    self.texY = [self _initTexture:GL_TEXTURE0];
    self.texU = [self _initTexture:GL_TEXTURE1];
    self.texV = [self _initTexture:GL_TEXTURE2];
    
    return GL_NO_ERROR == glGetError();
}

- (GLuint)_initTexture:(GLenum)tex
{
    GLuint ret;
    
    glGenTextures(1, &ret);
    glActiveTexture(tex);
    glBindTexture(GL_TEXTURE_2D, ret);
    VGLERR();
    
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    VGLERR();
    
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    VGLERR();
    
    glTexParameteri ( GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE ); // IMPORTANT!!
    glTexParameteri ( GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE );
    VGLERR();
    
    return ret;
}

@end
