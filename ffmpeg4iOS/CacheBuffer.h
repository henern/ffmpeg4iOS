
#import <Foundation/Foundation.h>


@interface CacheBuffer : NSObject {
	NSMutableArray *buffers;
	int writeIndex;
	int readIndex;
	NSLock *ringLock;
	NSLock *writeLock;
	NSLock *readLock;
}

- (id)initWithClass:(Class)class quantity:(int)quantity;
- (id)tryGetWriteBuffer;
- (void)putWriteBuffer;
- (id)tryGetReadBuffer;
- (void)putReadBuffer;
- (void)reset;

@end
