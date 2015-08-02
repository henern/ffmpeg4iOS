//
//  OGLProgram.h
//  ffmpeg4iOS
//
//  Created by Wayne W. on 13-5-28.
//
//

#import <Foundation/Foundation.h>
#import "OGLCommon.h"

@interface DEF_CLASS(OGLProgram) : NSObject

@property (nonatomic, assign) GLuint slotPosition;
@property (nonatomic, assign) GLuint slotTexCoordIn;

@property (nonatomic, assign) GLuint uniformTexY;
@property (nonatomic, assign) GLuint uniformTexU;
@property (nonatomic, assign) GLuint uniformTexV;

@property (nonatomic, assign) GLuint texY;
@property (nonatomic, assign) GLuint texU;
@property (nonatomic, assign) GLuint texV;

- (BOOL)activateTexY:(const void *)bytesY
                   U:(const void *)bytesU
                   V:(const void *)bytesV
               width:(GLsizei)width
              height:(GLsizei)height;

- (id)initWithVertShader:(const char*)vertShdr fragShader:(const char*)fragShdr;
- (BOOL)activate;

@end
