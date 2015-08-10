//
//  OGLProgram.h
//  ffmpeg4iOS
//
//  Created by Wayne W. on 13-5-28.
//
//

#import <Foundation/Foundation.h>
#import "OGLCommon.h"
#import "YUVBuffer.h"

@interface DEF_CLASS(OGLProgram) : NSObject

@property (nonatomic, assign) GLuint slotPosition;
@property (nonatomic, assign) GLuint slotTexCoordIn;

@property (nonatomic, assign) GLuint uniformTexY;
@property (nonatomic, assign) GLuint uniformTexU;
@property (nonatomic, assign) GLuint uniformTexV;
@property (nonatomic, assign) GLuint uniformTexUV;

@property (nonatomic, assign) GLuint texY;
@property (nonatomic, assign) GLuint texU;
@property (nonatomic, assign) GLuint texV;
@property (nonatomic, assign) GLuint texUV;

- (BOOL)activate;
- (instancetype)initWithPixFmt:(enum AVPixelFormat)pixFmt;
- (enum AVPixelFormat)pixel_format;
- (BOOL)activateTexBuffer:(id<DEF_CLASS(YUVBuffer)>)yuvBuf oglContext:(EAGLContext*)oglCtx;

@end
