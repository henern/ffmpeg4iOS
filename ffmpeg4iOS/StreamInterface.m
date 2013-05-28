
#import <libavcodec/avcodec.h>
#import <libavformat/avformat.h>

#import "StreamInterface.h"
#import "Player.h"

#define TCP_BUF_SIZE 4096


static StreamInterface *this = nil;


const char transcodeCommand[] = "ffmpeg -i - -async 10 -vcodec mpeg2video -b 200000 -r 20 -strict -1 -s 256x256 -deinterlace -acodec libmp3lame -ab 32000 -ac 1 -f mpegts -";


@implementation StreamInterface

@synthesize player;

@synthesize framePresentTime;




+ (StreamInterface *)interface {
	return this;
}


- (id)initWithPlayer:(id<ffmpegPlayer>)newPlayer server:(NSString *)newServer port:(unsigned short)newPort streamconvergTable:(NSString *)newTable username:(NSString *)newUsername password:(NSString *)newPassword {
	if (this) {
		NSLog(@"Error: Only one streamInterface may be instantiated at a time");
		[super dealloc];
		return nil;
	}
	return this;
	
	}


- (BOOL)connect {
			
	return true;
}


	


- (int64_t)seek:(int64_t)offset whence:(int)whence {
	return 0;
	NSLog(@"seeking...");
}


- (int)read:(uint8_t *)buffer length:(int)len {
	int ret = 0;
	
	assert(bytesRequested >= 0);
	
	int bytesRead = 0;
	
	while (readBuffer.length + bytesRead < len) {
		if (bytesRequested == 0) {
						if (ret < 0) {
				NSLog(@"Error: Failed to request streamtv stream block of size %d", len - bytesRequested - readBuffer.length);
				[readBuffer appendBytes:(buffer + readBuffer.length) length:bytesRead];
				return AVERROR(ret);
			}
			else if (ret == 0) {
				if (framePresentTime) { // Can't return EAGAIN during initial read or libav fails
					[readBuffer appendBytes:(buffer + readBuffer.length) length:bytesRead];
					return AVERROR(EAGAIN);
				}
				else {
					if (![self handleEvent]) {
						usleep(100000);
					}
					continue;
				}
			}
			else {
				bytesRequested += ret;
			}			
		}
		
		int64_t timeOutVal = framePresentTime - av_gettime();
		struct timeval timeOut;
		timeOut.tv_sec = (timeOutVal) / 1000000;
		timeOut.tv_usec = (timeOutVal) % 1000000;
		
		//ret = cstream_livetv_select(recorder, timeOutVal > 0 ? &timeOut : NULL);
		if (ret < 0) {
			NSLog(@"Error: Failed to select live tv recorder: %d", errno);
			[readBuffer appendBytes:(buffer + readBuffer.length) length:bytesRead];
			return AVERROR(ret);
		}
		else if (ret == 0) {
			[readBuffer appendBytes:(buffer + readBuffer.length) length:bytesRead];
			return AVERROR(EAGAIN);
		}
		
		//ret = cstream_livetv_get_block(recorder, (char *)buffer + bytesRead + readBuffer.length, bytesRequested);
		
		if (ret < 0) {
			[readBuffer appendBytes:(buffer + readBuffer.length) length:bytesRead];
			return AVERROR(ret);
		}
		
		bytesRequested -= ret;
		bytesRead += ret;
	}
	
	[readBuffer getBytes:buffer length:readBuffer.length];
	[readBuffer setLength:0];
	
	return len;
}


- (BOOL)cstreamRequestTimeoutLength:(struct timeval *)timeout {
	if (framePresentTime > 0) {
		int64_t timeoutVal = framePresentTime - av_gettime();

		if (timeoutVal <= 0) {
			[player presentFrame];
			timeoutVal = framePresentTime - av_gettime();
		}		
		
		if (timeoutVal > 0) {
			timeout->tv_sec = timeoutVal / 1000000;
			timeout->tv_usec = timeoutVal % 1000000;
			return YES;
		}
	}
	
	return NO;
}


- (BOOL)handleEvent {
	
	return NO;
}
	
	
- (void)disconnect
{
    NSAssert(0, @"TODO");
}

- (BOOL)startLiveTV
{
    NSAssert(0, @"TODO");
    return NO;
}


- (void)dealloc {
	[player release];
	[server release];
	[table release];
	[username release];
	[password release];
	[readBuffer release];
		[super dealloc];
	this = nil;
}


@end
