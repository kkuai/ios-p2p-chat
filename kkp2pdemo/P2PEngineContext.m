#import "P2PEngineContext.h"

@implementation P2PEngineContext
static P2PEngineContext *instance = nil;
+(P2PEngineContext *) getInstance{
    if (instance == nil) {
        instance = [[P2PEngineContext alloc] init];
    }
    
    return instance;
}

+(id) allocWithZone:(struct _NSZone*)zone
{
    if (instance == nil) {
        instance = [super allocWithZone:zone];
    }
    return instance;
}


-(id) copyWithZone:(struct _NSZone *)zone
{
    return instance;
}

@end
