
#import <UIKit/UIKit.h>
@class ListView;
@protocol ZCDropDownDelegate
- (void)dropDownDelegateMethod: (ListView *) sender;
@end
@class ListView;
@interface ListView : UIView<UITableViewDelegate, UITableViewDataSource>
{
    @public
    int downType;
}
- (void)hideDropDown:(UIButton *)button;
- (id)initWithShowDropDown:(UIButton *)button:(CGFloat )height:(NSArray *)arr:(int)myType;
@property (nonatomic, retain) id <ZCDropDownDelegate> delegate;

@end
