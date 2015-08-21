//
//  ADTSRaw.c
//  ffmpeg4iOS
//
//  Created by Wayne W on 15/8/22.
//  Copyright (c) 2015年 github.com/henern. All rights reserved.
//

#include "ADTSRaw.h"

#define FINISH()        goto DONE

int DEF_FUNC(checkADTSHeader)(const PBYTE8 data, int data_size)
{
    int len = 0;
    
    if (data == 0 || data_size <= sizeof(ADTS_FrameHeader))
    {
        FINISH();
    }
    
    ADTS_FrameHeader *header = (ADTS_FrameHeader*)data;
    if (!(header->SYNC_1 == 0xFF && header->SYNC_2 == 0xF))
    {
        FINISH();
    }
    
    if (!(header->LAYER == 0))
    {
        FINISH();
    }
    
    // should be ADTS
    len = sizeof(ADTS_FrameHeader);
    
    // it has CRC
    if (header->CRC_FLAG == 0)
    {
        len += sizeof(((ADTS_FrameHeader_CRC*)0)->CRC);
    }
    
DONE:
    return len;
}