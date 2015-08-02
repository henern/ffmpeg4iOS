//
//  AVCRaw.h
//  ffmpeg4iOS
//
//  Created by Wayne W on 14-8-13.
//
//

#ifndef BDMP4Utils_AVCRaw_h
#define BDMP4Utils_AVCRaw_h

#import "Common.h"

typedef struct
{
    BYTE8 configurationVersion;
    BYTE8 profileIndication;
    BYTE8 profileCompatibility;
    BYTE8 levelIndication;
    
    BYTE8 lengthSizeMinusOne;   // last 2-bit is valid
    
    // AVC_SequenceParameterSets
    // AVC_PictureParameterSets
    
}AVC_DecoderConfigurationRecord;

typedef struct
{
    BYTE8 number;       // last 5-bit is valid
    BYTE8 size[2];
    
    VARIABLE_LEN_ARRAY(BYTE8, NALUnits);
    
}AVC_SequenceParameterSets;

typedef struct
{
    BYTE8 number;
    BYTE8 size[2];
    
    VARIABLE_LEN_ARRAY(BYTE8, NALUnits);
    
}AVC_PictureParameterSets;

#endif
