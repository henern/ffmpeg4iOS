//
//  ADTSRaw.h
//  ffmpeg4iOS
//
//  Created by Wayne W on 15/8/22.
//  Copyright (c) 2015年 github.com/henern. All rights reserved.
//

#ifndef ffmpeg4iOS_ADTSRaw_h
#define ffmpeg4iOS_ADTSRaw_h

#import "Common.h"
#import "LibCommon.h"

#pragma pack(push)
#pragma pack(1)
typedef struct
{
    BYTE8 SYNC_1;           // 0xFF
    
    BYTE8 CRC_FLAG : 1;     // set to 1 if there is no CRC and 0 if there is CRC
    BYTE8 LAYER : 2;        // Layer: always 0
    BYTE8 MPEG_VER : 1;     // MPEG Version: 0 for MPEG-4, 1 for MPEG-2
    BYTE8 SYNC_2 : 4;       // 0xF
    
    BYTE8 placeholder[5];

}ADTS_FrameHeader;

typedef struct
{
    ADTS_FrameHeader basic_header;
    
    BYTE8 CRC[2];           // if CRC_FLAG
    
}ADTS_FrameHeader_CRC;
#pragma pack(pop)

// return-value == 0 --> if no ADTS header,
// return-value > 0  --> size of the header.
extern int DEF_FUNC(checkADTSHeader)(const PBYTE8 data, int data_size);

#endif
