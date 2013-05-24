//
#import <AudioToolbox/AudioQueue.h>
#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES1/gl.h>
#import <OpenGLES/ES1/glext.h>
#import <UIKit/UIKit.h>
#import "CacheBuffer.h"
#import "libavformat/avformat.h"

#define AUDIO_BUFFER_QUANTITY 3


@class FrameData;
@class StreamInterface;
@class CacheBuffer;


@interface Player : UIView {
	EAGLContext *context;
	GLuint renderbuffer;
	GLuint framebuffer;
	GLuint texture;
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
