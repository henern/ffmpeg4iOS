//
//  reference:
//  http://blog.csdn.net/xiaoguaihai/article/details/8672631
//  http://www.cocoachina.com/bbs/read.php?tid=100908
//  http://stackoverflow.com/questions/6432159/render-ypcbcr-iphone-4-camera-frame-to-an-opengl-es-2-0-texture-in-ios-4-3
//

#import <AudioToolbox/AudioQueue.h>
#import <UIKit/UIKit.h>
#import "CacheBuffer.h"
#import "libavformat/avformat.h"

#import "OGLCommon.h"       // common header for OGL
#import "ffmpegPlayer.h"

#define AUDIO_BUFFER_QUANTITY 3


@class FrameData;
@class StreamInterface;
@class CacheBuffer;


@interface OGLPlayer : UIView <ffmpegPlayer>
{
	EAGLContext *context;

	AVFormatContext *avfContext;
	int video_index;
	int audio_index;
	AVCodecContext *enc;
	CacheBuffer *videoBuffer;
	GLfloat points[8];
	GLfloat texturePoints[8];
	AVFrame *avFrame;
	BOOL frameReady;
	FrameData *currentVideoBuffer;
	double nextPts;
	AudioQueueRef audioQueue;
	AudioQueueBufferRef audioBuffers[AUDIO_BUFFER_QUANTITY];
	AudioQueueBufferRef emptyAudioBuffer;
	NSMutableArray *videoPacketQueue;
	NSMutableArray *audioPacketQueue;
	NSLock *audioPacketQueueLock;
	int decodeDone;
	NSLock *decodeDoneLock;
	BOOL seekRequested;
	float seekPosition;
	BOOL pauseRequested;
	NSLock *pauseLock;
	int64_t startTime;
	UInt64 trimmedFrames;
	StreamInterface *streamInterface;
	struct SwsContext *img_convert_ctx;
	unsigned int audioDTSQuotient;
	int audioPacketQueueSize;
}

@property (nonatomic, copy) NSString *path4Video;

- (BOOL)presentFrame;
- (void)pause;

@end
