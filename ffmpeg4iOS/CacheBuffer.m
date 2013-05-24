
#import "cacheBuffer.h"


@implementation CacheBuffer


- (id)initWithClass:(Class)class quantity:(int)quantity  {
	if (self = [super init]) {
		
		buffers = [[NSMutableArray alloc] initWithCapacity:quantity];
		
		int i;
		for (i = 0; i < quantity; i++) {
			id buffer = [[class alloc] init];
			[buffers addObject:buffer];
			[buffer release];
		}
	
		writeIndex = 0;
		readIndex = 0;
		
		ringLock = [[NSLock alloc] init];
		writeLock = [[NSLock alloc] init];
		readLock = [[NSLock alloc] init];
	}
	return self;
}


- (id)tryGetWriteBuffer {
	[ringLock lock];
	
	if ((writeIndex + 1) % buffers.count == readIndex || ![writeLock tryLock]) {
		[ringLock unlock];
		return nil;
	}
	
	[ringLock unlock];
	return [buffers objectAtIndex:writeIndex];
}


- (void)putWriteBuffer {
	[ringLock lock];
	
	writeIndex = (writeIndex + 1) % buffers.count;
	
	[writeLock unlock];
	
	[ringLock unlock];
}


- (id)tryGetReadBuffer {
	[ringLock lock];
	
	if (readIndex == writeIndex || ![readLock tryLock]) {
		[ringLock unlock];
		return nil;
	}
	
	[ringLock unlock];
	return [buffers objectAtIndex:readIndex];
}


- (void)putReadBuffer {
	[ringLock lock];
	
	readIndex = (readIndex + 1) % buffers.count;
	
	[readLock unlock];
	
	[ringLock unlock];
}


- (void)reset {
	[ringLock lock];
	[readLock lock];
	[writeLock lock];
	
	readIndex = 0;
	writeIndex = 0;
	
	[writeLock unlock];
	[readLock unlock];
	[ringLock unlock];
}


- (void)dealloc {
	[ringLock lock];
	[readLock lock];
	[writeLock lock];
	[buffers release];
	[writeLock unlock];
	[writeLock release];
	[readLock unlock];
	[readLock release];
	[ringLock unlock];
	[ringLock release];
	[super dealloc];
}


@end
