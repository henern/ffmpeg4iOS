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

@interface DEF_CLASS(OpenGLRender) ()
{        
    // opengl
    REF_CLASS(OGLProgram) m_oglProgram;
    EAGLContext *m_oglCtx;
    
    // buffer
    GLuint m_depthRenderBuffer;
    GLuint m_colorRenderBuffer;
    GLuint m_vertexBuffer;
    GLuint m_indexBuffer;
}

@end

@implementation DEF_CLASS(OpenGLRender)

+ (Class)renderLayerClass
{
    return [CAEAGLLayer class];
}

- (BOOL)drawYUV:(id<DEF_CLASS(YUVBuffer)>)yuvBuf enc:(AVCodecContext*)enc
{
    BOOL ret = YES;

    ret = [super drawYUV:yuvBuf enc:enc];
    CBRA(ret);
        
    ret = [self __drawYUV:yuvBuf];
    CBRA(ret);
    
ERROR:    
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

#pragma mark private
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

- (BOOL)__drawYUV:(id<DEF_CLASS(YUVBuffer)>)yuvBuf
{
    BOOL ret = YES;
    
    ret = [self __prepareContext4openGL];
    CBR(ret);
    
    ret = [self __buildProgram4buffer:yuvBuf];
    CBRA(ret);
    
    // buffer to texture
    ret = [m_oglProgram activateTexBuffer:yuvBuf];
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

- (BOOL)__buildProgram4buffer:(id<DEF_CLASS(YUVBuffer)>)yuvBuf
{
    BOOL ret = YES;
    
    if (m_oglProgram && [m_oglProgram pixel_format] == [yuvBuf pix_fmt])
    {
        // reuse
        FINISH();
    }
    
    // something wrong if we need to change the ogl-program
    VBR(m_oglProgram == nil);
    
    // build the program
    m_oglProgram = [[DEF_CLASS(OGLProgram) alloc] initWithPixFmt:[yuvBuf pix_fmt]];
    CPRA(m_oglProgram);
    
    ret = [m_oglProgram activate];
    VGLERR();
    CBRA(ret);
    
DONE:
ERROR:
    return ret;
}

@end
