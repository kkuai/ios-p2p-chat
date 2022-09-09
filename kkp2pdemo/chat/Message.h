#import <Foundation/Foundation.h>

typedef enum {
    MessageTypeMe = 0,
    MessageTypeOther = 1
} MessageType;

@interface Message : NSObject

/** 信息 */
@property(nonatomic, copy) NSString *text;

/** 发送时间 */
@property(nonatomic, copy) NSString *time;

/** 发送方 */
@property(nonatomic, assign) MessageType type;

/** 是否隐藏发送时间 */
@property(nonatomic, assign) BOOL hideTime;

- (instancetype) initWithDictionary:(NSDictionary *) dictionary;
+ (instancetype) messageWithDictionary:(NSDictionary *) dictionary;
+ (instancetype) message;

@end
