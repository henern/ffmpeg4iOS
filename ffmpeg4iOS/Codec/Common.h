//
//  Common.h
//  ffmpeg4iOS
//
//  Created by Wayne W on 14-7-11.
//
//

#ifndef BDMP4Utils_Common_h
#define BDMP4Utils_Common_h

#define LEN_OF_BYTE                 sizeof(uint8_t)
#define LEN_OF_BYTES_4_UINT16       2
#define LEN_OF_BYTES_4_UINT24       3
#define LEN_OF_BYTES_4_UINT32       4
#define LEN_OF_BYTES_4_DOUBLE       sizeof(double)

/*
 *  data-type definition
 */
#define BYTE8       uint8_t
#define PBYTE8      BYTE8*
#define PVOID       void*
#define LONG64      long long

// helper macro to define the member
#define BINT32(name)                    BYTE8 name[4]
#define BINT24(name)                    BYTE8 name[3]
#define VARIABLE_LEN_ARRAY(type, name)  type name[1]

// 
extern uint16_t BINT16ToUInt16(const PBYTE8 raw);
extern uint32_t BINT32ToUInt32(const PBYTE8 raw);         // big-endian bytes ==> UInt32

//
#define PTR_BYTE_BUFFER(NAME, TYPE, LEN)    BYTE8 __BUF_##NAME##__[(LEN)] = {0};    \
                                            assert((LEN) >= sizeof(TYPE));          \
                                            TYPE* NAME = (TYPE*)__BUF_##NAME##__

#define SIZE_OF_PTR_BYTE_BUFFER(NAME)       sizeof(__BUF_##NAME##__)

#endif
