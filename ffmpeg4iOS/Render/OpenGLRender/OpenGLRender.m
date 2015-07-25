//
//  OpenGLRender.m
//  ffmpeg4iOS
//
//  Created by Wayne W. on 15/7/16.
//  Copyright (c) 2015年 github.com/henern. All rights reserved.
//

#import "OpenGLRender.h"
#import "ehm.h"
#import "OGLProgram.h"
#import "Shaders.h"

@interface DEF_CLASS(OpenGLRender) ()
{
    GLfloat points[8];
    GLfloat texturePoints[8];
        
    // opengl
    REF_CLASS(OGLProgram) m_oglProgram;
    EAGLContext *m_oglCtx;
    
    // buffer
    GLuint m_depthRenderBuffer;
    GLuint m_colorRenderBuffer;
    GLuint m_vertexBuffer;
    GLuint m_indexBuffer;
    
    // frame buffer
    NSMutableData *m_bufferYUV;
}

@end

@implementation DEF_CLASS(OpenGLRender)

+ (Class)renderLayerClass
{
    return [CAEAGLLayer class];
}

- (BOOL)drawFrame:(AVFrame *)avfDecoded enc:(AVCodecContext*)enc
{
    BOOL ret = YES;
    int err = ERR_SUCCESS;
    
    AVFrame *avpicYUV = av_frame_alloc();
    
    CPRA(m_bufferYUV);
    CPR(enc);
    CBRA(m_bufferYUV.length >= [self __size_per_picture_YUV420P]);
    
    ret = [super drawFrame:avfDecoded enc:enc];
    CBRA(ret);
    
    // binding
    err = avpicture_fill((AVPicture*)avpicYUV, [m_bufferYUV mutableBytes], enc->pix_fmt, enc->width, enc->height);
    CBRA(err >= 0);
    
    // copy from planes to plain buffer
    av_picture_copy((AVPicture*)avpicYUV, (AVPicture *)avfDecoded, enc->pix_fmt, enc->width, enc->height);
    
    [self __drawYUV:[m_bufferYUV mutableBytes] width:enc->width height:enc->height];
    
ERROR:
    if (avpicYUV)
    {
        av_frame_free(&avpicYUV);
        avpicYUV = NULL;
    }
    
    return ret;
}

- (BOOL)attachToView:(UIView *)view
{
    BOOL ret = YES;
    CGRect frame = CGRectZero;
    
    CAEAGLLayer *layer = (CAEAGLLayer *)view.layer;
    CBRA([layer isKindOfClass:[[self class] renderLayerClass]]);
    
    ret = [super attachToView:view];
    CBRA(ret);
    frame = self.ref_drawingView.bounds;
    
    // properties
    layer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:
                                [NSNumber numberWithBool:NO],   kEAGLDrawablePropertyRetainedBacking,
                                kEAGLColorFormatRGB565,         kEAGLDrawablePropertyColorFormat, nil];
    
    ret = [self __prepareContext4openGL];
    CBRA(ret);
    
    ret = [self __setupBuffers4context:m_oglCtx layer:layer view:view];
    CBRA(ret);
    
    // build the program
    m_oglProgram = [[DEF_CLASS(OGLProgram) alloc] initWithVertShader:VERTEX_SHADER
                                                          fragShader:FRAGMENT_SHADER];
    [m_oglProgram activate];
    VGLERR();
    
    // build buffer objects
    ret = [self __setupVBOs];
    CBRA(ret);
    
    glViewport(0, 0, frame.size.width, frame.size.height);
    glScissor(0, 0, frame.size.width, frame.size.height);
    CBRA(OGLRET);
    
    glDisable(GL_DITHER);
    CBRA(OGLRET);
    
ERROR:
    return ret;
}

- (BOOL)attachTo:(AVStream*)stream err:(int*)errCode atIndex:(int)index
{
    BOOL ret = [super attachTo:stream err:errCode atIndex:index];
    CBRA(ret);
    
    ret = [self __setup2stream:stream err:errCode];
    CBRA(ret);
    
ERROR:
    return ret;
}

#pragma mark private
- (BOOL)__setup2stream:(AVStream*)stream err:(int*)errCode
{
    BOOL ret = YES;
    
    if ((float)self.bounds.size.height / self.bounds.size.width > self.aspectRatio)
    {
        GLfloat blank = (self.bounds.size.height - self.bounds.size.width * self.aspectRatio) / 2;
        points[0] = self.bounds.size.width;
        points[1] = self.bounds.size.height - blank;
        points[2] = 0;
        points[3] = self.bounds.size.height - blank;
        points[4] = self.bounds.size.width;
        points[5] = blank;
        points[6] = 0;
        points[7] = blank;
    }
    else
    {
        GLfloat blank = (self.bounds.size.width - (float)self.bounds.size.height / self.aspectRatio) / 2;
        points[0] = self.bounds.size.width - blank;
        points[1] = self.bounds.size.height;
        points[2] = blank;
        points[3] = self.bounds.size.height;
        points[4] = self.bounds.size.width - blank;
        points[5] = 0;
        points[6] = blank;
        points[7] = 0;
    }
    
    texturePoints[0] = 0;
    texturePoints[1] = 0;
    texturePoints[2] = 0;
    texturePoints[3] = 1;
    texturePoints[4] = 1;
    texturePoints[5] = 0;
    texturePoints[6] = 1;
    texturePoints[7] = 1;
    
    // allocate the YUV buffer
    m_bufferYUV = [NSMutableData dataWithLength:[self __size_per_picture_YUV420P]];
    CPR(m_bufferYUV);
    
ERROR:
    return ret;
}

- (BOOL)__setupBuffers4context:(EAGLContext*)ctx layer:(CAEAGLLayer*)eaglLayer view:(UIView*)drawingView
{
    VHOSTTHREAD();
    
    glGenRenderbuffers(1, &m_depthRenderBuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, m_depthRenderBuffer);
    glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT16, drawingView.frame.size.width, drawingView.frame.size.height);
    VGLERR();
    
    glGenRenderbuffers(1, &m_colorRenderBuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, m_colorRenderBuffer);
    [ctx renderbufferStorage:GL_RENDERBUFFER fromDrawable:eaglLayer];
    VGLERR();
    
    GLuint framebuffer;
    glGenFramebuffers(1, &framebuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, framebuffer);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, m_colorRenderBuffer);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, m_depthRenderBuffer);
    VGLERR();
    
    return OGLRET;
}

- (BOOL)__setupVBOs
{
    VHOSTTHREAD();
    
    glGenBuffers(1, &m_vertexBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, m_vertexBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(Vertices), Vertices, GL_STATIC_DRAW);
    
    glGenBuffers(1, &m_indexBuffer);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, m_indexBuffer);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(Indices), Indices, GL_STATIC_DRAW);
    
    return OGLRET;
}

- (BOOL)__drawYUV:(uint8_t *)dataYUV width:(float)width height:(float)height
{
    BOOL ret = YES;
    
    ret = [self __prepareContext4openGL];
    CBR(ret);
    
    // buffer to texture
    ret = [m_oglProgram activateTexYUV4buffer:dataYUV
                                        width:width
                                       height:height];
    CBR(ret);
    
    // draw with tex
    ret = [self __renderTexture];
    CBRA(ret);
    
    // present
    ret = [m_oglCtx presentRenderbuffer:GL_RENDERBUFFER_OES];
    CBRA(ret);
    
ERROR:
    return ret;
}

- (BOOL)__renderTexture
{
    BOOL ret = YES;
    
    glClear(GL_COLOR_BUFFER_BIT);
    CBRA(OGLRET);
    
    glBindBuffer(GL_ARRAY_BUFFER, m_vertexBuffer);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, m_indexBuffer);
    
    glVertexAttribPointer(m_oglProgram.slotPosition,
                          3, GL_FLOAT,
                          GL_FALSE,
                          sizeof(Vertex), 0);
    VGLERR();
    glVertexAttribPointer(m_oglProgram.slotTexCoordIn,
                          2, GL_FLOAT,
                          GL_FALSE,
                          sizeof(Vertex),
                          (GLvoid*) (sizeof(float) * 7));
    VGLERR();
    
    glDrawElements(GL_TRIANGLES, sizeof(Indices)/sizeof(Indices[0]), GL_UNSIGNED_BYTE, 0);
    CBRA(OGLRET);
    
ERROR:
    return ret;
}

- (int)__size_per_picture_YUV420P
{
    AVCodecContext *ctx = [self ctx_codec];
    if (!ctx)
    {
        VBR(0);
        return 0;
    }
    
    return avpicture_get_size(PIX_FMT_YUV420P, ctx->width, ctx->height);
}

- (BOOL)__prepareContext4openGL
{
    BOOL ret = YES;
    
    if (!m_oglCtx)
    {
        // must use ES2
        m_oglCtx = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    }
    CPRA(m_oglCtx);
    
    if ([EAGLContext currentContext] != m_oglCtx)
    {
        ret = [EAGLContext setCurrentContext:m_oglCtx];
        CBRA(ret);
    }
    
ERROR:
    return ret;
}

@end
