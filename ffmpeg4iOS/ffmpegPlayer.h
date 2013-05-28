//
//  ffmpegPlayer.h
//  ffmpeg4iOS
//
//  Created by Wayne W. on 13-5-29.
//
//

#ifndef ffmpeg4iOS_ffmpegPlayer_h
#define ffmpeg4iOS_ffmpegPlayer_h


#import <AudioToolbox/AudioToolbox.h>

@protocol ffmpegPlayer <NSObject>
- (void)fillAudioBuffer:(AudioQueueBufferRef)buffer;
- (BOOL)presentFrame;
@end

#endif
