#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface NSString (Extension)

/** 测量文本的尺寸 */
- (CGSize) sizeWithFont:(UIFont *)font maxSize:(CGSize) maxSize;

@end
