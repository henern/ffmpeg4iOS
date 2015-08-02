//
//  Common.m
//  ffmpeg4iOS
//
//  Created by Wayne W on 14-7-11.
//
//

#import "Common.h"

uint32_t BINT32ToUInt32(const PBYTE8 raw)
{
    uint32_t dword = 0;
    BYTE8 tmp[LEN_OF_BYTES_4_UINT32] = {0};
    
    // it's big-endian
    if (raw)
    {
        tmp[LEN_OF_BYTES_4_UINT32 - 1] = *raw;
        tmp[LEN_OF_BYTES_4_UINT32 - 2] = *(raw + 1);
        tmp[LEN_OF_BYTES_4_UINT32 - 3] = *(raw + 2);
        tmp[LEN_OF_BYTES_4_UINT32 - 4] = *(raw + 3);
        
        dword = *((uint32_t*)(&tmp[0]));
    }
    
    return dword;
}

uint16_t BINT16ToUInt16(const PBYTE8 raw)
{
    UInt16 word = 0;
    BYTE8 tmp[LEN_OF_BYTES_4_UINT16] = {0};
    
    // it's big-endian
    if (raw)
    {
        tmp[LEN_OF_BYTES_4_UINT16 - 1] = *raw;
        tmp[LEN_OF_BYTES_4_UINT16 - 2] = *(raw + 1);
        
        word = *((UInt16*)(&tmp[0]));
    }
    
    return word;
}
