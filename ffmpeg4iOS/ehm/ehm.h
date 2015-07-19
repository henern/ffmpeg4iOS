//
//  ehm.h
//  ffmpeg4iOS
//
//  Created by Wayne W. on 13-5-28.
//
//

#ifndef ffmpeg4iOS_ehm_h
#define ffmpeg4iOS_ehm_h

#define VBR(x)      assert((x))
#define VPR(p)      assert(nil != (p))
#define VMAINTHREAD()       assert([NSThread isMainThread])

#define VGLERR()    assert(GL_NO_ERROR == glGetError())
#define OGLRET      (GL_NO_ERROR == glGetError())

#define UNUSE(x)    ((void)(x))

/*
 *  check macros
 */
#define CBR(x)                                                  \
    do {                                                        \
        if (NO == (x))                                          \
        {                                                       \
            ret = NO;                                           \
            goto ERROR;                                         \
        }                                                       \
    } while(0)

#define CBRA(x)                                                 \
    do {                                                        \
        if (NO == (x))                                          \
        {                                                       \
            ret = NO;                                           \
            VBR(0);                                             \
            goto ERROR;                                         \
        }                                                       \
    } while(0)

#define CPR(p)                                                  \
    do {                                                        \
        if (nil == (p))                                         \
        {                                                       \
            ret = NO;                                           \
            goto ERROR;                                         \
        }                                                       \
    } while(0)

#define CCBRA(x)                                                \
                                                                \
if (!(x))                                                       \
{                                                               \
    VBR(0);                                                     \
    continue;                                                   \
}

#define CCBR(x)                                                 \
                                                                \
if (!(x))                                                       \
{                                                               \
    continue;                                                   \
}

#define CPRA(p)                                                 \
    do {                                                        \
        if (nil == (p))                                         \
        {                                                       \
            ret = NO;                                           \
            VBR(0);                                             \
            goto ERROR;                                         \
        }                                                       \
    } while(0)

#define FINISH()                    goto DONE

/*
 *  const definition
 */
#define ERR_SUCCESS                 0

// error domain for NSError
extern NSString * const FFMPEG4IOS_ERR_DOMAIN;


#endif
