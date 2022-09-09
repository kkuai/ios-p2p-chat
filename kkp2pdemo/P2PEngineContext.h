#import "kkp2p_sdk.h"
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface P2PEngineContext : NSObject
{
@public
    NSString *loginDomain;
    NSString *loginPort;
    NSString *lanSearchPort;
    NSString *connMode;
    NSString *loginName;
    kkp2p_engine_t* p2pEngine;
}

+ (P2PEngineContext *) getInstance;

@end

NS_ASSUME_NONNULL_END
