
#import <Foundation/Foundation.h>


@interface FrameData : NSObject {
	NSMutableData *data;
	int64_t pts;
}


@property (retain) NSMutableData *data;
@property (assign) int64_t pts;

@end
