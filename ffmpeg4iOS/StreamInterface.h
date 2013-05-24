
#import <Foundation/Foundation.h>




@class streamControlThreadObject;
@class Player;


@interface StreamInterface : NSObject {
	Player *player;
	NSString *server;
	unsigned short port;
	NSString *table;
	NSString *username;
	NSString *password;
	
	int64_t framePresentTime;
	int bytesRequested;
	NSMutableData *readBuffer;
}


+ (StreamInterface *)interface;


- (id)initWithPlayer:(Player *)player server:(NSString *)newServer port:(unsigned short)newPort streamconvergTable:(NSString *)newTable username:(NSString *)newUsername password:(NSString *)newPassword;
- (BOOL)connect;
- (void)disconnect;
- (BOOL)startLiveTV;
- (int64_t)seek:(int64_t)offset whence:(int)whence;
- (int)read:(uint8_t *)buffer length:(int)len;
- (BOOL)handleEvent;
- (BOOL)cstreamRequestTimeoutLength:(struct timeval *)timeout;


@property (readonly) Player *player;

@property (assign) int64_t framePresentTime;


@end
