#import "UIImage+Extension.h"

@implementation UIImage (Extension)

+ (UIImage *) resizableImage:(NSString *) imageName {
    UIImage *image = [UIImage imageNamed:imageName];
    // 取图片中部的1 x 1进行拉伸
    UIEdgeInsets insets = UIEdgeInsetsMake(image.size.height/2, image.size.width/2, image.size.height/2 + 1, image.size.width/2 + 1);
    return [image resizableImageWithCapInsets:insets];
}

@end
