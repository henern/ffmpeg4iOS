//
//  Player.m
// 
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program; if not, write to the Free Software
//  Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
//

#import "FrameData.h"
#import "StreamInterface.h"

#import "Player.h"
#import "CacheBuffer.h"
#import "libavcodec/avcodec.h"
#import "libavdevice/avdevice.h"
#import "libavformat/avio.h"
#import "libswscale/swscale.h"


#import <AudioToolbox/AudioToolbox.h>
#import <OpenGLES/EAGLDrawable.h>
#import <QuartzCore/QuartzCore.h>


#define FRAME_X 1024
#define FRAME_Y 1024

#define VIDEO_BUFFER_QUANTITY 10
#define VIDEO_QUEUE_SIZE_MAX 5 * 25 * 1024
#define AUDIO_QUEUE_SIZE_MAX 5 * 16 * 1024

#define AUDIO_BUFFER_SECONDS 1

void audioQueueOutputCallback(void *info, AudioQueueRef AudioQueue, AudioQueueBufferRef buffer);
int avReadPacket(void *opaque, uint8_t *buf, int buf_size);
int64_t avSeek(void *opaque, int64_t offset, int whence);


@interface Player (Private)
- (void)renderFrameToTexture:(FrameData *)frame;
- (void)renderTexture;
- (void)fillAudioBuffer:(AudioQueueBufferRef)buffer;
@end


@implementation Player
@synthesize path4Video = _path4Video;

+ (Class)layerClass {
	return [CAEAGLLayer class];
}


- (id)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
		videoBuffer = [[CacheBuffer alloc] initWithClass:([FrameData class]) quantity:VIDEO_BUFFER_QUANTITY];
		
		avFrame = avcodec_alloc_frame();
		
		CAEAGLLayer *layer = (CAEAGLLayer *)self.layer;
		layer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:NO], kEAGLDrawablePropertyRetainedBacking, kEAGLColorFormatRGB565, kEAGLDrawablePropertyColorFormat, nil];
		context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES1];
		
		if (![EAGLContext setCurrentContext:context]) {
			NSLog(@"Error: Failed to set current openGL context in [Player initWithFrame:]");
			[super dealloc];
			return nil;
		}
		
		int err = 0;
		
		glGenRenderbuffersOES(1, &renderbuffer);
		if (err = glGetError()) {
			NSLog(@"Error: Could not generate render buffer: %d", err);
			[super dealloc];
			return nil;
		}
		
		glBindRenderbufferOES(GL_RENDERBUFFER_OES, renderbuffer);
		if (err = glGetError()) {
			NSLog(@"Error: Could not bind render buffer: %d", err);
			glDeleteRenderbuffersOES(1, &renderbuffer);
			[super dealloc];
			return nil;
		}
		
		if (![context renderbufferStorage:GL_RENDERBUFFER_OES fromDrawable:layer]) {
			NSLog(@"Error: Could not bind layer to render buffer");
			glDeleteRenderbuffersOES(1, &renderbuffer);
			[super dealloc];
			return nil;
		}
		
		glGenFramebuffersOES(1, &framebuffer);
		if (err = glGetError()) {
			NSLog(@"Error: Could not generate frame buffer: %d", err);
			glDeleteRenderbuffersOES(1, &renderbuffer);
			[super dealloc];
			return nil;
		}
		
		glBindFramebufferOES(GL_FRAMEBUFFER_OES, framebuffer);
		if (err = glGetError()) {
			NSLog(@"Error: Could not bind frame buffer: %d", err);
			glDeleteFramebuffersOES(1, &framebuffer);
			glDeleteRenderbuffersOES(1, &renderbuffer);
			[super dealloc];
			return nil;
		}
		
		glFramebufferRenderbufferOES(GL_FRAMEBUFFER_OES, GL_COLOR_ATTACHMENT0_OES, GL_RENDERBUFFER_OES, renderbuffer);
		if (err = glGetError()) {
			NSLog(@"Error: Could not bind render buffer to frame buffer: %d", err);
			glDeleteFramebuffersOES(1, &framebuffer);
			glDeleteRenderbuffersOES(1, &renderbuffer);
			[super dealloc];
			return nil;
		}
		
		glViewport(0, 0, frame.size.width, frame.size.height);
		if (err = glGetError()) {
			NSLog(@"Error: Could not set viewport: %d", err);
			glDeleteFramebuffersOES(1, &framebuffer);
			glDeleteRenderbuffersOES(1, &renderbuffer);
			[super dealloc];
			return nil;
		}

		glScissor(0, 0, frame.size.width, frame.size.height);
		if (err = glGetError()) {
			NSLog(@"Error: Could not set scissors: %d", err);
			glDeleteFramebuffersOES(1, &framebuffer);
			glDeleteRenderbuffersOES(1, &renderbuffer);
			[super dealloc];
			return nil;
		}
		
		glGenTextures(1, &texture);
		if (err = glGetError()) {
			NSLog(@"Error: Could not generate texture: %d", err);
			glDeleteFramebuffersOES(1, &framebuffer);
			glDeleteRenderbuffersOES(1, &renderbuffer);
			[super dealloc];
			return nil;
		}

		glBindTexture(GL_TEXTURE_2D, texture);
		if (err = glGetError()) {
			NSLog(@"Error: Could not bind texture: %d", err);
			glDeleteTextures(1, &texture);
			glDeleteFramebuffersOES(1, &framebuffer);
			glDeleteRenderbuffersOES(1, &renderbuffer);
			[super dealloc];
			return nil;
		}

		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
		if (err = glGetError()) {
			NSLog(@"Error: Could not set texture minimization filter: %d", err);
			glDeleteTextures(1, &texture);
			glDeleteFramebuffersOES(1, &framebuffer);
			glDeleteRenderbuffersOES(1, &renderbuffer);
			[super dealloc];
			return nil;
		}

		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
		if (err = glGetError()) {
			NSLog(@"Error: Could not set texture magnification filter: %d", err);
			glDeleteTextures(1, &texture);
			glDeleteFramebuffersOES(1, &framebuffer);
			glDeleteRenderbuffersOES(1, &renderbuffer);
			[super dealloc];
			return nil;
		}
		
		glDisable(GL_DITHER);
		if (err = glGetError()) {
			NSLog(@"Error: Could not enable dither support: %d", err);
			glDeleteTextures(1, &texture);
			glDeleteFramebuffersOES(1, &framebuffer);
			glDeleteRenderbuffersOES(1, &renderbuffer);
			[super dealloc];
			return nil;
		}

		glMatrixMode(GL_PROJECTION);
		if (err = glGetError()) {
			NSLog(@"Error: Could not enable projection matrix mode: %d", err);
			glDeleteTextures(1, &texture);
			glDeleteFramebuffersOES(1, &framebuffer);
			glDeleteRenderbuffersOES(1, &renderbuffer);
			[super dealloc];
			return nil;
		}

		glOrthof(0, frame.size.width, 0, frame.size.height, -1, 1);
		if (err = glGetError()) {
			NSLog(@"Error: Could not set view matrix: %d", err);
			glDeleteTextures(1, &texture);
			glDeleteFramebuffersOES(1, &framebuffer);
			glDeleteRenderbuffersOES(1, &renderbuffer);
			[super dealloc];
			return nil;
		}

		glMatrixMode(GL_MODELVIEW);
		if (err = glGetError()) {
			NSLog(@"Error: Could not set model view matrix mode: %d", err);
			glDeleteTextures(1, &texture);
			glDeleteFramebuffersOES(1, &framebuffer);
			glDeleteRenderbuffersOES(1, &renderbuffer);
			[super dealloc];
			return nil;
		}

		glEnable(GL_TEXTURE_2D);
		if (err = glGetError()) {
			NSLog(@"Error: Could not enable textures: %d", err);
			glDeleteTextures(1, &texture);
			glDeleteFramebuffersOES(1, &framebuffer);
			glDeleteRenderbuffersOES(1, &renderbuffer);
			[super dealloc];
			return nil;
		}

		glEnableClientState(GL_VERTEX_ARRAY);
		if (err = glGetError()) {
			NSLog(@"Error: Could not enable vertex arrays: %d", err);
			glDeleteTextures(1, &texture);
			glDeleteFramebuffersOES(1, &framebuffer);
			glDeleteRenderbuffersOES(1, &renderbuffer);
			[super dealloc];
			return nil;
		}

		glEnableClientState(GL_TEXTURE_COORD_ARRAY);
		if (err = glGetError()) {
			NSLog(@"Error: Could not enable texture vertex arrays: %d", err);
			glDeleteTextures(1, &texture);
			glDeleteFramebuffersOES(1, &framebuffer);
			glDeleteRenderbuffersOES(1, &renderbuffer);
			[super dealloc];
			return nil;
		}

		glTexEnvf(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_REPLACE);
		if (err = glGetError()) {
			NSLog(@"Error: Could not enable texture replacement mode: %d", err);
			glDeleteTextures(1, &texture);
			glDeleteFramebuffersOES(1, &framebuffer);
			glDeleteRenderbuffersOES(1, &renderbuffer);
			[super dealloc];
			return nil;
		}
		
		videoPacketQueue = [[NSMutableArray alloc] init];
		
		pauseLock = [[NSLock alloc] init];
		decodeDoneLock = [[NSLock alloc] init];
		
		self.multipleTouchEnabled = YES;
		self.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    }
    return self;
}

- (void)setPath4Video:(NSString *)path4Video
{
    _path4Video = [path4Video copy];
    
    if (_path4Video && [_path4Video length] > 0)
    {
        [NSThread detachNewThreadSelector:@selector(videoThread) toTarget:self withObject:nil];
    }
}

- (void)videoThread {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	int64_t videoDtsOffset = 0;
	int64_t audioDtsOffset = 0;
	int64_t prevVideoDts = 0;
	int64_t prevAudioDts = 0;
	BOOL primed = false;
	int pictureReady = false;
	double picturePts;
	int videoPacketQueueSize = 0;
	audioPacketQueueSize = 0;
	int err;
	
	[NSThread setThreadPriority:1];
	
		
	streamInterface = [[StreamInterface alloc] initWithPlayer:self server:nil port:6541 streamconvergTable:@"streamconverg" username:nil password:nil];
	//	NSLog(@"Error: Could not create a new MythTV interface");
	//	glDeleteTextures(1, &texture);
	//	glDeleteFramebuffersOES(1, &framebuffer);
	//	glDeleteRenderbuffersOES(1, &renderbuffer);
	//	[super dealloc];
	//	return nil;
	//	}
	
	
	
	//register_protocol(&MythProtocol);
	av_register_all();  // TODO:
    
	NSString *videoPath = [self path4Video];
#if 0
	NSString   *videoPath=@"http://172.16.1.48:9000/disk/DLNA-PNAVI-OP01-FLAGS01700000/video/O0$3$27I15/101%2DRising1%262.AVI";
#endif
	const char *filename = [videoPath UTF8String];
	
	
#ifdef _USE_DEPRECATED_FFMPEG_METHODS
	err = av_open_input_file(&avfContext, filename, NULL, 0, NULL);
#else
    err = avformat_open_input(&avfContext, filename, NULL, NULL);
#endif
		
	if (err) {
		NSLog(@"Error: Could not open mythtv stream: %d", err);
		
		return;
	}
	else {
		NSLog(@"Opened stream");
	}
	
	err = av_find_stream_info(avfContext);
	if (err < 0) {
		NSLog(@"Error: Could not find stream info: %d", err);
				return;
	}
	else {
		NSLog(@"Found stream info");
	}
	
	video_index = -1;
	audio_index = -1;
	
	int i;
	for(i = 0; i < avfContext->nb_streams; i++) {
		enc = avfContext->streams[i]->codec;
		avfContext->streams[i]->discard = AVDISCARD_ALL;
		switch(enc->codec_type) {
			case CODEC_TYPE_VIDEO:
				video_index = i;
			 avfContext->streams[i]->discard = AVDISCARD_NONE;
				break;
			case CODEC_TYPE_AUDIO:
				audio_index = i;
			 avfContext->streams[i]->discard = AVDISCARD_NONE;
			default:
				break;
		}
	}
	
	if (video_index >= 0) {
		avfContext->streams[video_index]->discard = AVDISCARD_DEFAULT;
	}
	
	if (audio_index >= 0) {
		avfContext->streams[audio_index]->discard = AVDISCARD_DEFAULT;
	}
	
	float aspectRatio = av_q2d(avfContext->streams[video_index]->codec->sample_aspect_ratio);
	if (!aspectRatio) {
		aspectRatio = av_q2d(avfContext->streams[video_index]->sample_aspect_ratio);
	}
	if (!aspectRatio) {
		NSLog(@"No aspect ratio found, assuming 4:3");
		aspectRatio = 4.0 / 3;
	}
	
	if ((float)self.bounds.size.height / self.bounds.size.width > aspectRatio) {
		GLfloat blank = (self.bounds.size.height - self.bounds.size.width * aspectRatio) / 2;
		points[0] = self.bounds.size.width;
		points[1] = self.bounds.size.height - blank;
		points[2] = 0;
		points[3] = self.bounds.size.height - blank;
		points[4] = self.bounds.size.width;
		points[5] = blank;
		points[6] = 0;
		points[7] = blank;
	}
	else {
		GLfloat blank = (self.bounds.size.width - (float)self.bounds.size.height / aspectRatio) / 2;
		points[0] = self.bounds.size.width - blank;
		points[1] = self.bounds.size.height;
		points[2] = blank;
		points[3] = self.bounds.size.height;
		points[4] = self.bounds.size.width - blank;
		points[5] = 0;
		points[6] = blank;
		points[7] = 0;
	}
	
	texturePoints[0] = 0;
	texturePoints[1] = 0;
	texturePoints[2] = 0;
	texturePoints[3] = 1;
	texturePoints[4] = 1;
	texturePoints[5] = 0;
	texturePoints[6] = 1;
	texturePoints[7] = 1;
	
	enc = avfContext->streams[video_index]->codec;
	AVCodec *codec = avcodec_find_decoder(enc->codec_id);
	if (!codec) {
		NSLog(@"Error: Could not find decoder for video codec %d", enc->codec_id);
		av_close_input_file(avfContext);
				return;
	}
	
	err = avcodec_open(enc, codec);
	if (err < 0) {
		NSLog(@"Error: Could not open video decoder: %d", err);
		av_close_input_file(avfContext);
			return;
	}
	
	/*
	 
	 /*
	 if (audioFormat.mFormatID != -1) {
	 audioFormat.mSampleRate = avfContext->streams[audio_index]->codec->sample_rate;
	 audioFormat.mBytesPerPacket = 0;
	 audioFormat.mFramesPerPacket = avfContext->streams[audio_index]->codec->frame_size;
	 audioFormat.mBytesPerFrame = avfContext->streams[audio_index]->codec->frame_bits *8;
	 audioFormat.mChannelsPerFrame = avfContext->streams[audio_index]->codec->channels;
	 audioFormat.mBitsPerChannel =  avfContext->streams[audio_index]->codec->bits_per_raw_sample;
	 */
	

	
	if (audio_index >= 0) {
		AudioStreamBasicDescription audioFormat;
		audioFormat.mFormatID = -1;
		audioFormat.mSampleRate = avfContext->streams[audio_index]->codec->sample_rate;
		audioFormat.mFormatFlags = 0;
		switch (avfContext->streams[audio_index]->codec->codec_id) {
			case CODEC_ID_MP3:
				audioFormat.mFormatID = kAudioFormatMPEGLayer3;
				break;
			case CODEC_ID_AAC:
				audioFormat.mFormatID = kAudioFormatMPEG4AAC;
				audioFormat.mFormatFlags = kMPEG4Object_AAC_Main;
				break;
			case CODEC_ID_AC3:
				audioFormat.mFormatID = kAudioFormatAC3;
				break;
			default:
				NSLog(@"Error: audio format '%s' (%d) is not supported", avfContext->streams[audio_index]->codec->codec_name, avfContext->streams[audio_index]->codec->codec_id);
				audioFormat.mFormatID = kAudioFormatAC3;				
				break;
		}
		
		if (audioFormat.mFormatID != -1) {
			audioFormat.mBytesPerPacket = 0;
			audioFormat.mFramesPerPacket = avfContext->streams[audio_index]->codec->frame_size;
			audioFormat.mBytesPerFrame = 0;
			audioFormat.mChannelsPerFrame = avfContext->streams[audio_index]->codec->channels;
			audioFormat.mBitsPerChannel = 0;
			
			if (err = AudioQueueNewOutput(&audioFormat, audioQueueOutputCallback, self, NULL, NULL, 0, &audioQueue)) {
				NSLog(@"Error creating audio output queue: %d", err);
				avfContext->streams[audio_index]->discard = AVDISCARD_ALL;
				audio_index = -1;
			}
			else {
				for (i = 0; i < AUDIO_BUFFER_QUANTITY; i++) {
					NSLog(@"%d packet capacity, %d byte capacity", (int)(avfContext->streams[audio_index]->codec->sample_rate * AUDIO_BUFFER_SECONDS / avfContext->streams[audio_index]->codec->frame_size + 1), (int)(avfContext->streams[audio_index]->codec->bit_rate * AUDIO_BUFFER_SECONDS / 8));
					if (err = AudioQueueAllocateBufferWithPacketDescriptions(audioQueue, avfContext->streams[audio_index]->codec->bit_rate * AUDIO_BUFFER_SECONDS / 8, avfContext->streams[audio_index]->codec->sample_rate * AUDIO_BUFFER_SECONDS / avfContext->streams[audio_index]->codec->frame_size + 1, audioBuffers + i)) {
						NSLog(@"Error: Could not allocate audio queue buffer: %d", err);
						avfContext->streams[audio_index]->discard = AVDISCARD_ALL;
						audio_index = -1;
						AudioQueueDispose(audioQueue, YES);
						break;
					}
				}					
			}
			
			if (audio_index >= 0) {
				audioPacketQueue = [[NSMutableArray alloc] init];
				audioPacketQueueLock = [[NSLock alloc] init];
			}
		}
		else {
			avfContext->streams[audio_index]->discard = AVDISCARD_ALL;
			audio_index = -1;
		}
	}
	
	decodeDone = 0;
	startTime = 0;
	
	while (frameReady || pictureReady || !decodeDone) {
		if (seekRequested) {
			if (av_seek_frame(avfContext, -1, seekPosition * avfContext->duration, 0) < 0) {
				NSLog(@"Error while seeking to position %f", seekPosition);
			}
			else {
				decodeDone = 0;
				primed = false;
				frameReady = false;
				pictureReady = false;
				startTime = 0;
				
				for (NSMutableData *packetData in videoPacketQueue) {
					av_free_packet([packetData mutableBytes]);
				}
				[videoPacketQueue removeAllObjects];
				videoPacketQueueSize = 0;
				
				[audioPacketQueueLock lock];
				for (NSMutableData *packetData in audioPacketQueue) {
					av_free_packet([packetData mutableBytes]);
				}
				[audioPacketQueue removeAllObjects];
				audioPacketQueueSize = 0;
				[audioPacketQueueLock unlock];
				
				[videoBuffer reset];
				
				AudioQueueStop(audioQueue, YES);
			}
			
			seekRequested = NO;
		}
		
		float video;
		float audio;
		
		BOOL presentFrame = (startTime - av_gettime() + nextPts <= 0);
		
		if (audio_index >= 0 && video_index >= 0 && frameReady && presentFrame && startTime > 0) {
			AudioTimeStamp timeStamp;
			AudioQueueGetCurrentTime(audioQueue, NULL, &timeStamp, NULL);
			video = nextPts / 1000000;
			audio = (float)timeStamp.mSampleTime / avfContext->streams[audio_index]->codec->sample_rate;
			
			startTime += (int)((video - audio) * 1000000);
			streamInterface.framePresentTime = startTime + nextPts;
		}
		
		if (primed && frameReady && presentFrame && !pauseRequested) {
			if (startTime == 0) {
				startTime = av_gettime() - nextPts;
				if (audio_index >= 0) {
					if (err = AudioQueueStart(audioQueue, NULL)) {
						NSLog(@"Error: Audio queue failed to start: %d", err);
					}
					else {
						NSLog(@"Started audio queue");
					}
				}
			}
			[self presentFrame];
			continue;
		}
		
		if (!frameReady && (currentVideoBuffer = [videoBuffer tryGetReadBuffer])) {
			[self renderFrameToTexture:currentVideoBuffer];
			nextPts = currentVideoBuffer.pts;
			//streamInterface.framePresentTime = startTime + nextPts;
			if (startTime > 0) { 
			  streamInterface.framePresentTime = startTime + nextPts; 
			} 
			[videoBuffer putReadBuffer];
			[self renderTexture];
			frameReady = true;
			continue;
		}		
		
		if (pictureReady && (currentVideoBuffer = [videoBuffer tryGetWriteBuffer])) {
			AVPicture picture;
			
			if (currentVideoBuffer.data.length < 2 * FRAME_X * FRAME_Y) {
				[currentVideoBuffer.data setLength:(2 * FRAME_X * FRAME_Y)];
			}
			
			avpicture_fill(&picture, [currentVideoBuffer.data mutableBytes], PIX_FMT_RGB565, FRAME_X, FRAME_Y);
			if (!(img_convert_ctx = sws_getCachedContext(img_convert_ctx, enc->width, enc->height, enc->pix_fmt, FRAME_X, FRAME_Y, PIX_FMT_RGB565, SWS_FAST_BILINEAR, NULL, NULL, NULL))) {
				NSLog(@"Error: Failed to get swscale context");
			}
			else {
				sws_scale(img_convert_ctx, avFrame->data, avFrame->linesize, 0, enc->height, picture.data, picture.linesize);
			}
			
			currentVideoBuffer.pts = picturePts;
			
			[videoBuffer putWriteBuffer];			
			
			pictureReady = false;
			
			continue;
		}
		
		if (!pictureReady && videoPacketQueue.count) {
			NSMutableData *packetData = [videoPacketQueue objectAtIndex:0];
			AVPacket *currentPacket = [packetData mutableBytes];
			
			videoPacketQueueSize -= currentPacket->size;
			
			avfContext->streams[video_index]->codec->reordered_opaque = currentPacket->pts;
			//if ((err = avcodec_decode_video(enc, avFrame, &pictureReady, currentPacket->data, currentPacket->size)) < 0) {
			if ((err = avcodec_decode_video2(enc, avFrame, &pictureReady, currentPacket)) < 0) {

				NSLog(@"Error decoding video: %d", err);
			}

			if (currentPacket->dts == AV_NOPTS_VALUE && avFrame->reordered_opaque != AV_NOPTS_VALUE) {
				picturePts = avFrame->reordered_opaque;
			}
			else if (currentPacket->dts != AV_NOPTS_VALUE) {
				picturePts = currentPacket->dts;
			}
			else {
				picturePts = 0;
			}
			
			if (picturePts < 0) {
				picturePts = 0;
			}
			
			if (prevVideoDts > picturePts) {
				videoDtsOffset += prevVideoDts - picturePts;
			}
			prevVideoDts = picturePts;
			
			picturePts += videoDtsOffset;
			picturePts *= av_q2d(avfContext->streams[video_index]->time_base) * 1000000;
			
			av_free_packet(currentPacket);
			[videoPacketQueue removeObjectAtIndex:0];
			
			continue;
		}
		
		if (primed && !videoPacketQueue.count) {
			NSLog(@"Warning: Video packet queue empty");
		}
		
		if ([[StreamInterface interface] handleEvent]) {
			continue;
		}
		
		if (videoPacketQueue.count <= 0 && primed && !decodeDone && !pauseRequested) {
			NSLog(@"Pausing to buffer...");
			primed = false;
			startTime = 0;
			AudioQueuePause(audioQueue);
			emptyAudioBuffer = nil;
			streamInterface.framePresentTime = 0;
			}
		
		
		if (!decodeDone && videoPacketQueueSize < VIDEO_QUEUE_SIZE_MAX && audioPacketQueueSize < AUDIO_QUEUE_SIZE_MAX) {
			AVPacket packet;
			while (1) {
				[decodeDoneLock lock];
				decodeDone = av_read_frame(avfContext, &packet);
				if (decodeDone) {
					if (decodeDone == AVERROR(EAGAIN) && avfContext->pb->error == AVERROR(EAGAIN)) { 
						decodeDone = 0;
						avfContext->pb->eof_reached = 0;
						avfContext->pb->error = 0;
					}
					[decodeDoneLock unlock];
					break;
				}
				[decodeDoneLock unlock];
				
				if (avfContext->pb->eof_reached && avfContext->pb->error == AVERROR(EAGAIN)) {
					avfContext->pb->eof_reached = 0;
					avfContext->pb->error = 0;
				}
				
				if (packet.stream_index != video_index && packet.stream_index != audio_index) {
					av_free_packet(&packet);
					continue;
				}
				
				if ((err = av_dup_packet(&packet)) < 0) {
					NSLog(@"Error duplicating packet: %d", err);
					continue;
				}
				
				if (packet.stream_index == video_index) {
					videoPacketQueueSize += packet.size;
					[videoPacketQueue addObject:[NSMutableData dataWithBytes:&packet length:sizeof(packet)]];
				}
				else {
					if (!audioDTSQuotient && packet.dts > 0) {
						audioDTSQuotient = packet.dts;
					}
					
					if (audioDTSQuotient > 0) {
						packet.dts /= audioDTSQuotient;
					}
					
					if (packet.dts < 0) {
						packet.dts = 0;
					}
					
					if (prevAudioDts > packet.dts) {
						audioDtsOffset += prevAudioDts - packet.dts;
					}
					prevAudioDts = packet.dts;
					
					packet.dts += audioDtsOffset;
					
					[audioPacketQueueLock lock];
					audioPacketQueueSize += packet.size;
					[audioPacketQueue addObject:[NSMutableData dataWithBytes:&packet length:sizeof(packet)]];
					[audioPacketQueueLock unlock];
					
					if (emptyAudioBuffer) {
						[self fillAudioBuffer:emptyAudioBuffer];
					}
				}
				break;
			}
			if (videoPacketQueue.count > 0 || audioPacketQueue.count > 0) { 
				continue; 
				} 
			} 
		                 
		if (!decodeDone && videoPacketQueue.count <= 0) { 
			NSLog(@"Audio packet queue is full while video packet queue is empty, flushing audio queue"); 
			[audioPacketQueueLock lock]; 
			for (NSMutableData *packetData in audioPacketQueue) { 
				av_free_packet([packetData mutableBytes]); 
				} 
			[audioPacketQueue removeAllObjects]; 
			audioPacketQueueSize = 0; 
			[audioPacketQueueLock unlock]; 
			continue;
		}
		
		if (!primed) {
			if (audio_index >= 0) {
				int i;
				for (i = 0; i < AUDIO_BUFFER_QUANTITY; i++) {
					[self fillAudioBuffer:audioBuffers[i]];
				}
				
				if (err = AudioQueuePrime(audioQueue, 0, NULL)) {
					NSLog(@"Error: Failed to prime audio queue: %d", err);
				}
			}
			
			primed = true;
			
			continue;
		}
		
		if (pauseRequested) {
			[pauseLock lock];
			[pauseLock unlock];
			
			startTime = av_gettime() - nextPts;
		}
		else {
			int64_t delay = startTime - av_gettime() + nextPts;
			
			if (delay > 0) {
				struct timespec ts;
				ts.tv_sec = delay / 1000000;
				ts.tv_nsec = (delay % 1000000) * 1000;
				
				if (nanosleep(&ts, NULL) && errno != EINTR) {
					NSLog(@"nanosleep failed (%d, %d): %s", ts.tv_sec, ts.tv_nsec, strerror(errno));
				}				
			}
		}
	}
	
	[pool release];
}


- (void)renderFrameToTexture:(FrameData *)frame {
	if ([EAGLContext currentContext] != context) {
		if (![EAGLContext setCurrentContext:context]) {
			NSLog(@"Error: Failed to set current openGL context in [Player renderFrameToTexture:]");
			return;
		}
	}
	
	glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, FRAME_X, FRAME_Y, 0, GL_RGB, GL_UNSIGNED_SHORT_5_6_5, [frame.data bytes]);
	
	int err;
	if (err = glGetError()) {
		NSLog(@"glTexImage2D Error: %d", err);
	}
}

	
- (void)renderTexture {
	int err;
	
	glClear(GL_COLOR_BUFFER_BIT);
	if (err = glGetError()) {
		NSLog(@"Error: Could not clear frame buffer: %d", err);
	}
	
	glVertexPointer(2, GL_FLOAT, 0, points);
	if (err = glGetError()) {
		NSLog(@"Error: Could not create vertex array: %d", err);
		return;
	}
	
	glTexCoordPointer(2, GL_FLOAT, 0, texturePoints);
	if (err = glGetError()) {
		NSLog(@"Error: Could not create texture vertex array: %d", err);
		return;
	}
	
	glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
	if (err = glGetError()) {
		NSLog(@"Error: Could not draw texture: %d", err);
	}
}


- (BOOL)presentFrame {
	if (startTime - av_gettime() + nextPts > 0) {
		return FALSE;
	}
	
	if (![context presentRenderbuffer:GL_RENDERBUFFER_OES]) {
		NSLog(@"Error: Failed to present renderbuffer");
	}
	
	frameReady = false;

	if (currentVideoBuffer = [videoBuffer tryGetReadBuffer]) {
		[self renderFrameToTexture:currentVideoBuffer];
		nextPts = currentVideoBuffer.pts;
	
		[videoBuffer putReadBuffer];
		[self renderTexture];
		frameReady = true;
	}
	else {
		streamInterface.framePresentTime = 0;
	}
	
	return TRUE;
}
			
			
void audioQueueOutputCallback(void *info, AudioQueueRef unused, AudioQueueBufferRef buffer) {
	[(Player *)info fillAudioBuffer:buffer];
}


- (void)fillAudioBuffer:(AudioQueueBufferRef)buffer {
	AudioTimeStamp bufferStartTime;
	
	buffer->mAudioDataByteSize = 0;
	buffer->mPacketDescriptionCount = 0;
	
	if (audioPacketQueue.count <= 0) {
		NSLog(@"Warning: No audio packets in queue");
		emptyAudioBuffer = buffer;
		return;
	}
	
	emptyAudioBuffer = nil;
	
	while (audioPacketQueue.count && buffer->mPacketDescriptionCount < buffer->mPacketDescriptionCapacity) {
		NSMutableData *packetData = [audioPacketQueue objectAtIndex:0];
		AVPacket *packet = [packetData mutableBytes];
		
		if (buffer->mAudioDataBytesCapacity - buffer->mAudioDataByteSize >= packet->size) {
			if (buffer->mPacketDescriptionCount == 0) {
				bufferStartTime.mSampleTime = packet->dts * avfContext->streams[audio_index]->codec->frame_size;
				bufferStartTime.mFlags = kAudioTimeStampSampleTimeValid;
			}
			
			memcpy((uint8_t *)buffer->mAudioData + buffer->mAudioDataByteSize, packet->data, packet->size);
			buffer->mPacketDescriptions[buffer->mPacketDescriptionCount].mStartOffset = buffer->mAudioDataByteSize;
			buffer->mPacketDescriptions[buffer->mPacketDescriptionCount].mDataByteSize = packet->size;
			buffer->mPacketDescriptions[buffer->mPacketDescriptionCount].mVariableFramesInPacket = avfContext->streams[audio_index]->codec->frame_size;
			
			buffer->mAudioDataByteSize += packet->size;
			buffer->mPacketDescriptionCount++;
			
			[audioPacketQueueLock lock];
			audioPacketQueueSize -= packet->size;
			[audioPacketQueue removeObjectAtIndex:0];
			[audioPacketQueueLock unlock];

			av_free_packet(packet);
		}
		else {
			break;
		}
	}
	
	if (buffer->mPacketDescriptionCount > 0) {
		OSStatus err;
		
		if (err = AudioQueueEnqueueBufferWithParameters(audioQueue, buffer, 0, NULL, 0, 0, 0, NULL, &bufferStartTime, NULL)) {
			NSLog(@"Error enqueuing audio buffer: %d", err);
		}
		
		[decodeDoneLock lock];
		if (decodeDone && audioPacketQueue.count == 0) {
			if (err = AudioQueueStop(audioQueue, false)) {
				NSLog(@"Error: Failed to stop audio queue: %d", err);
			}
			else {
				NSLog(@"Stopped audio queue");
			}
		}
		[decodeDoneLock unlock];
	}
}


- (void)seek:(float)offset {
	seekRequested = YES;
	seekPosition = offset;
}


- (void)pause {
	if (!pauseRequested) {
		pauseRequested = YES;
		AudioQueuePause(audioQueue);
		[pauseLock lock];
	}
	else {
		pauseRequested = NO;
		AudioQueueStart(audioQueue, NULL);
		[pauseLock unlock];
	}
}


int64_t avSeek(void *opaque, int64_t offset, int whence) {
	return [(StreamInterface *)opaque seek:offset whence:whence];
}


- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
	if (touches.count == 1) {
		[self pause];
	}
	else {
		[self seek:0];
	}
}


- (void)dealloc {
	[pauseLock lock];
	[pauseLock unlock];
	[pauseLock release];
	[StreamInterface release];
	[videoPacketQueue release];
	if (audio_index) {
		[audioPacketQueueLock lock];
		[audioPacketQueue release];
		[audioPacketQueueLock unlock];
		[audioPacketQueueLock release];
		AudioQueueDispose(audioQueue, YES);
	}
	sws_freeContext(img_convert_ctx);
	avcodec_close(enc);
	av_close_input_file(avfContext);
	glDeleteTextures(1, &texture);
	glDeleteFramebuffersOES(1, &framebuffer);
	glDeleteRenderbuffersOES(1, &renderbuffer);
	av_free(avFrame);
	[videoBuffer release];
    [super dealloc];
}


@end
