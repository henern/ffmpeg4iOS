#import "FrameData.h"


@implementation FrameData


@synthesize data;
@synthesize pts;

@synthesize width;
@synthesize height;


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
