#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "Message.h"

#define MESSAGE_TIME_FONT [UIFont systemFontOfSize:13]
#define MESSAGE_TEXT_FONT [UIFont systemFontOfSize:15]
#define TEXT_INSET 20

@interface MessageFrame : NSObject

/** 发送时间  */
@property(nonatomic, assign, readonly) CGRect timeFrame;

/** 头像 */
@property(nonatomic, assign, readonly) CGRect iconFrame;

/** 信息 */
@property(nonatomic, assign, readonly) CGRect textFrame;

/** 信息model */
@property(nonatomic, strong) Message *message;

/** cell的高度 */
@property(nonatomic, assign) CGFloat cellHeight;


@end
