
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface KKP2PChannel : NSObject {
    @public
    NSString* peer_id;
    int channel_type;
    int  transmit_mode;
    int  encrypt_data;
    uint32_t channel_id;
    int fd;
}

@end

NS_ASSUME_NONNULL_END
