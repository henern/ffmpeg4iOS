#import "FrameData.h"


@implementation FrameData


@synthesize data;
@synthesize pts;


- (id)init {
	if (self = [super init]) {
		data = [[NSMutableData alloc] init];
	}
	return self;
}


- (void)dealloc {
	[data release];
	[super dealloc];
}


@end
